import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:songbuddy/models/AppUser.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'backend_api_service.dart';
import 'http_client_service.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Simple HTTP client with basic configuration (for health checks only)
class SimpleHttpClient {
  static Future<Response> delete(String url,
      {Map<String, String>? headers, Object? body}) async {
    final response = await HttpClientService.instance
        .delete(url, options: Options(headers: headers), data: body);
    return response;
  }

  static Future<Response> post(String url,
      {Map<String, String>? headers, Object? body}) async {
    final response = await HttpClientService.instance
        .post(url, options: Options(headers: headers), data: body);
    return response;
  }

  static Future<Response> get(String url,
      {Map<String, String>? headers}) async {
    final response = await HttpClientService.instance
        .get(url, options: Options(headers: headers));
    return response;
  }

  static Future<Response> put(String url,
      {Map<String, String>? headers, Object? body}) async {
    final response = await HttpClientService.instance
        .put(url, options: Options(headers: headers), data: body);
    return response;
  }
}

class BackendService {
  // Constant base URL for backend - using computer's IP for mobile debugging
  // Update this IP address whenever your computer's IP changes

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  // HTTP client with token refresh capabilities
  final HttpClientService _httpClient = HttpClientService.instance;

  /// Initialize the HTTP client with auth service for token management
  void initializeAuth(AuthService authService) {
    _httpClient.setAuthService(authService);
  }

  // Alternative IPs to try if the main one fails
  static const List<String> alternativeUrls = [
    'http://192.168.83.108:3000', // Current IP (Wi-Fi)
    'http://192.168.56.1:3000', // Ethernet adapter
    'http://192.168.32.2:3000', // Ethernet 6 adapter
    'http://192.168.1.108:3000', // Common home network
    'http://192.168.227.108:3000', // Previous IP
    'http://10.0.2.2:3000', // Android emulator
    'http://localhost:3000', // Local development
  ];

  /// Clear any cached backend URLs to force rediscovery
  static void clearCache() {
    BackendApiService.clearBackendCache();
  }

  /// Test all possible backend URLs and return the working one
  static Future<String?> testAllUrls() async {
    print('🔍 BackendService: Testing all possible backend URLs...');

    for (String url in alternativeUrls) {
      try {
        print('🔍 BackendService: Testing URL: $url');
        final response = await SimpleHttpClient.get(
          "$url/health",
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          print('✅ BackendService: SUCCESS! Working URL: $url');
          return url;
        } else {
          print(
              '❌ BackendService: URL $url returned status ${response.statusCode}');
        }
      } catch (e) {
        print('❌ BackendService: URL $url failed: $e');
      }
    }

    print('❌ BackendService: No working URLs found!');
    return null;
  }

  /// Test backend connection before making requests
  Future<bool> testConnection() async {
    try {
      final response = await SimpleHttpClient.get(
        "$baseUrl/health",
        headers: {"Content-Type": "application/json"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend connection test failed: $e');
      return false;
    }
  }

  /// Find working backend URL by trying alternatives
  Future<String?> findWorkingBackendUrl() async {
    print('🔍 BackendService: Trying to find working backend URL...');

    for (String url in alternativeUrls) {
      try {
        print('🔍 BackendService: Trying URL: $url');
        final response = await SimpleHttpClient.get(
          "$url/health",
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          print('✅ BackendService: Found working URL: $url');
          return url;
        }
      } catch (e) {
        print('❌ BackendService: URL $url failed: $e');
        continue;
      }
    }

    print('❌ BackendService: No working backend URL found');
    return null;
  }

  Future<AppUser?> saveUser(AppUser user) async {
    final url = "$baseUrl/api/users/save";
    print('🔗 BackendService: Attempting to save user to: $url');

    try {
      final response = await _httpClient.post(
        url,
        data: user.toJson(),
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      print(
          '📡 BackendService: Save user response - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        return AppUser(
          id: data['id'] ?? '',
          displayName: data['displayName'] ?? '',
          email: data['email'] ?? '',
          profilePicture: data['profilePicture'] ?? '',
          country: data['country'] ?? 'US',
          currentlyPlaying: data['currentlyPlaying'],
          topArtists: data['topArtists'] != null
              ? List<Map<String, dynamic>>.from(data['topArtists'])
              : [],
          topTracks: data['topTracks'] != null
              ? List<Map<String, dynamic>>.from(data['topTracks'])
              : [],
          recentlyPlayed: data['recentlyPlayed'] != null
              ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
              : [],
        );
      } else {
        throw Exception(
            "Failed to save user: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Save user error: $e');
      throw Exception("Failed to save user: $e");
    }
  }

  /// Update user fields (all fields except id are updatable)
  Future<AppUser?> updateUser(
      String userId, Map<String, dynamic> updates) async {
    final response = await SimpleHttpClient.put(
      "$baseUrl/api/users/$userId",
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return AppUser(
        id: data['id'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'] ?? '',
        country: data['country'] ?? 'US',
        currentlyPlaying: data['currentlyPlaying'],
        topArtists: data['topArtists'] != null
            ? List<Map<String, dynamic>>.from(data['topArtists'])
            : [],
        topTracks: data['topTracks'] != null
            ? List<Map<String, dynamic>>.from(data['topTracks'])
            : [],
        recentlyPlayed: data['recentlyPlayed'] != null
            ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
            : [],
      );
    } else {
      throw Exception("Failed to update user: ${response.data}");
    }
  }

  /// Delete user from backend
  Future<bool> deleteUser(String userId) async {
    try {
      print(
          '🔗 BackendService: Deleting user $userId from: $baseUrl/api/users/$userId');

      final response = await SimpleHttpClient.delete(
        "$baseUrl/api/users/$userId",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Connection": "keep-alive",
        },
      );

      print(
          '📡 BackendService: Delete response - Status: ${response.statusCode}, Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
            "Failed to delete user: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Delete user error: $e');

      if (e
          .toString()
          .contains("Connection closed before full header was received")) {
        throw Exception(
            "Connection lost: Backend server may have closed the connection. Please try again.");
      } else if (e.toString().contains("Connection refused")) {
        throw Exception(
            "Cannot connect to backend server. Please check if the server is running.");
      } else if (e.toString().contains("Request timeout")) {
        throw Exception(
            "Request timeout: Backend took too long to respond. Please try again.");
      } else {
        throw Exception("Failed to delete user: $e");
      }
    }
  }

  /// Get user information from backend
  Future<AppUser?> getUser(String userId) async {
    final response = await SimpleHttpClient.get(
      "$baseUrl/api/users/$userId",
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return AppUser(
        id: data['id'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'] ?? '',
        country: data['country'] ?? 'US',
        currentlyPlaying: data['currentlyPlaying'],
        topArtists: data['topArtists'] != null
            ? List<Map<String, dynamic>>.from(data['topArtists'])
            : [],
        topTracks: data['topTracks'] != null
            ? List<Map<String, dynamic>>.from(data['topTracks'])
            : [],
        recentlyPlayed: data['recentlyPlayed'] != null
            ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
            : [],
        following: data['following'] != null
            ? List<String>.from(data['following'])
            : [],
        followers: data['followers'] != null
            ? List<String>.from(data['followers'])
            : [],
        postCount: data['postCount'] ?? 0,
      );
    } else {
      throw Exception("Failed to get user: ${response.data}");
    }
  }

  // ===== POST-RELATED METHODS =====

  /// Create a new post
  Future<Post> createPost(Post post) async {
    final url = "$baseUrl/api/posts/create";
    print('🔗 BackendService: Creating post at: $url');

    // Debug: Print the JSON being sent
    final postJson = post.toJson();
    print('🔍 BackendService: Sending JSON: ${jsonEncode(postJson)}');

    // Debug: Check if username field exists and is not empty
    if (postJson['username'] == null) {
      print('❌ BackendService: Username field is NULL in JSON');
    } else if (postJson['username'].toString().isEmpty) {
      print('❌ BackendService: Username field is EMPTY in JSON');
    } else {
      print(
          '✅ BackendService: Username field exists: "${postJson['username']}"');
    }

    try {
      final response = await SimpleHttpClient.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Connection": "keep-alive",
        },
        body: jsonEncode(postJson),
      );

      print(
          '📡 BackendService: Create post response - Status: ${response.statusCode}, Body: ${response.data}');

      if (response.statusCode == 201) {
        final data = response.data;
        print('🔍 BackendService: Backend returned data: $data');

        try {
          return Post.fromJson(data);
        } catch (e) {
          print('❌ BackendService: Error parsing Post.fromJson: $e');
          print('❌ BackendService: Data that failed to parse: $data');
          throw Exception("Failed to parse post data from backend: $e");
        }
      } else {
        throw Exception(
            "Failed to create post: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Create post error: $e');

      if (e
          .toString()
          .contains("Connection closed before full header was received")) {
        throw Exception(
            "Connection lost: Backend server may have closed the connection. Please try again.");
      } else if (e.toString().contains("Connection refused")) {
        throw Exception(
            "Cannot connect to backend server. Please check if the server is running.");
      } else if (e.toString().contains("Request timeout")) {
        throw Exception(
            "Request timeout: Backend took too long to respond. Please try again.");
      } else {
        throw Exception("Failed to create post: $e");
      }
    }
  }

  /// Get posts from users that the current user follows (for home feed)
  Future<List<Post>> getFollowingPosts(String userId,
      {int limit = 20, int offset = 0, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/following/$userId?limit=$limit&offset=$offset${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";
    print('🔗 BackendService: Getting following posts from: $url');

    final response = await SimpleHttpClient.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final posts = (data['posts'] as List<dynamic>? ?? [])
          .map((post) => Post.fromJson(post))
          .toList();
      return posts;
    } else {
      throw Exception("Failed to get following posts: ${response.data}");
    }
  }

  /// Get feed posts (posts from users that the current user follows)
  Future<List<Post>> getFeedPosts(String userId,
      {int limit = 20, int offset = 0, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/feed/$userId?limit=$limit&offset=$offset${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";
    print('🔗 BackendService: Getting feed posts from: $url');

    final response = await _httpClient.get(
      url,
      options: Options(
        headers: {"Content-Type": "application/json"},
        // Allow longer response time for hosted backends with cold starts
        receiveTimeout: const Duration(seconds: 75),
      ),
    );

    print('📡 BackendService: Feed response - Status: ${response.statusCode}');
    print('📡 BackendService: Raw response body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      print('🔍 BackendService: Parsed JSON data: $data');
      print(
          '🔍 BackendService: Data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');

      // Check different possible response structures
      List<dynamic> postsList = [];

      if (data['posts'] != null) {
        postsList = data['posts'] as List<dynamic>;
        print(
            '📊 BackendService: Found posts in data["posts"]: ${postsList.length} items');
      } else if (data['data'] != null) {
        postsList = data['data'] as List<dynamic>;
        print(
            '📊 BackendService: Found posts in data["data"]: ${postsList.length} items');
      } else if (data is List) {
        postsList = data;
        print(
            '📊 BackendService: Data is directly a list: ${postsList.length} items');
      } else {
        print(
            '❌ BackendService: No posts found in response. Available keys: ${data.keys.toList()}');
        return [];
      }

      final posts = postsList.map((post) {
        print('🔍 BackendService: Processing post: $post');
        return Post.fromJson(post);
      }).toList();

      print(
          '📊 BackendService: Successfully parsed ${posts.length} posts from feed');
      return posts;
    } else {
      throw Exception("Failed to get feed posts: ${response.data}");
    }
  }

  /// Search users by name, username, or email (server-side filtering)
  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int page = 1, int limit = 20}) async {
    final url =
        "$baseUrl/api/users/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit";
    print('🔗 BackendService: Searching users with query: "$query"');
    print('🔍 BackendService: URL -> $url');

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Search users response - Status: ${response.statusCode}');

      // Handle no results (404)
      if (response.statusCode == 404) {
        print('⚠️ BackendService: No users found for query "$query"');
        return [];
      }

      // Handle successful response
      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['data'] is List) {
          final users = List<Map<String, dynamic>>.from(data['data']);
          print('✅ BackendService: Found ${users.length} users');
          return users;
        }
      }

      throw Exception('Unexpected response format: ${response.statusCode}');
    } catch (e) {
      print('❌ BackendService: Search error: $e');
      return [];
    }
  }

  /// Get discovery posts (Instagram-style) from users not followed
  Future<List<Map<String, dynamic>>> getDiscoveryPosts(
      {String? userId, int page = 1, int limit = 20}) async {
    final url =
        "$baseUrl/api/posts/discovery?userId=${Uri.encodeComponent(userId ?? '')}&page=$page&limit=$limit";
    print('🔗 BackendService: Getting discovery posts for user: $userId');
    print('🔍 BackendService: URL -> $url');

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Discovery posts response - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['data'] is List) {
          final posts = List<Map<String, dynamic>>.from(data['data']);
          print('✅ BackendService: Found ${posts.length} discovery posts');
          return posts;
        }
      }

      throw Exception('Unexpected response format: ${response.statusCode}');
    } catch (e) {
      print('❌ BackendService: Discovery posts error: $e');
      return [];
    }
  }

  /// Search posts by song name, artist, or description
  Future<List<Post>> searchPosts(String query,
      {int page = 1, int limit = 20, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";
    print('🔗 BackendService: Searching posts with query: "$query"');

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Search posts response - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final posts = (data['data'] as List<dynamic>)
              .map((post) => Post.fromJson(post))
              .toList();
          print('✅ BackendService: Found ${posts.length} posts');
          return posts;
        } else {
          print('❌ BackendService: Search posts failed: ${data['message']}');
          return [];
        }
      } else {
        throw Exception(
            "Failed to search posts: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Search posts error: $e');
      throw Exception("Failed to search posts: $e");
    }
  }

  /// Like a post
  Future<bool> likePost(String postId, String userId) async {
    final url = "$baseUrl/api/posts/$postId/like";
    print('🔗 BackendService: Liking post: $postId');

    final response = await SimpleHttpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data['liked'] as bool? ?? false;
    } else {
      throw Exception("Failed to like post: ${response.data}");
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId, String userId) async {
    final url = "$baseUrl/api/posts/$postId/like";
    print('🔗 BackendService: Unliking post: $postId');

    final response = await SimpleHttpClient.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data['liked'] as bool? ?? false;
    } else {
      throw Exception("Failed to unlike post: ${response.data}");
    }
  }

  /// Toggle like/unlike a post (smart method that determines action based on current state)
  Future<bool> togglePostLike(
      String postId, String userId, bool currentLikeState) async {
    if (currentLikeState) {
      // Currently liked, so unlike
      return await unlikePost(postId, userId);
    } else {
      // Currently not liked, so like
      return await likePost(postId, userId);
    }
  }

  /// Update a post (edit description)
  Future<Post> updatePost(
      String postId, String userId, String description) async {
    final url = "$baseUrl/api/posts/$postId";
    print(
        '🔗 BackendService: Updating post: $postId with description: $description');

    final response = await SimpleHttpClient.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "description": description,
      }),
    );

    print(
        '📡 BackendService: Update response - Status: ${response.statusCode}, Body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      return Post.fromJson(data);
    } else {
      throw Exception("Failed to update post: ${response.data}");
    }
  }

  /// Follow a user
  Future<Map<String, dynamic>> followUser(
      String currentUserId, String targetUserId) async {
    final url = "$baseUrl/api/users/$targetUserId/follow";
    print('🔗 BackendService: Following user: $currentUserId -> $targetUserId');

    final response = await SimpleHttpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "followerId": currentUserId,
      }),
    );

    print(
        '📡 BackendService: Follow response - Status: ${response.statusCode}, Body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        print('✅ BackendService: Successfully followed user');
        return data['data'];
      } else {
        throw Exception("Failed to follow user: ${data['message']}");
      }
    } else {
      throw Exception(
          "Failed to follow user: ${response.statusCode} - ${response.data}");
    }
  }

  /// Unfollow a user
  Future<Map<String, dynamic>> unfollowUser(
      String currentUserId, String targetUserId) async {
    final url = "$baseUrl/api/users/$targetUserId/follow";
    print(
        '🔗 BackendService: Unfollowing user: $currentUserId -> $targetUserId');

    final response = await SimpleHttpClient.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "followerId": currentUserId,
      }),
    );

    print(
        '📡 BackendService: Unfollow response - Status: ${response.statusCode}, Body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        print('✅ BackendService: Successfully unfollowed user');
        return data['data'];
      } else {
        throw Exception("Failed to unfollow user: ${data['message']}");
      }
    } else {
      throw Exception(
          "Failed to unfollow user: ${response.statusCode} - ${response.data}");
    }
  }

  /// Check follow status
  Future<Map<String, dynamic>> getFollowStatus(
      String currentUserId, String targetUserId) async {
    final url =
        "$baseUrl/api/users/$targetUserId/follow-status?currentUserId=$currentUserId";
    print(
        '🔗 BackendService: Checking follow status: $currentUserId -> $targetUserId');

    final response = await SimpleHttpClient.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    print(
        '📡 BackendService: Follow status response - Status: ${response.statusCode}, Body: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        print('✅ BackendService: Successfully got follow status');
        return data['data'];
      } else {
        throw Exception("Failed to get follow status: ${data['message']}");
      }
    } else {
      throw Exception(
          "Failed to get follow status: ${response.statusCode} - ${response.data}");
    }
  }

  /// Get user's followers
  Future<List<Map<String, dynamic>>> getUserFollowers(String userId,
      {int page = 1, int limit = 20}) async {
    final url = "$baseUrl/api/users/$userId/followers?page=$page&limit=$limit";
    print('🔗 BackendService: Getting followers for user: $userId');

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Followers response - Status: ${response.statusCode}, Body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ BackendService: Successfully got followers');
          // Handle case where data might be null or undefined
          if (data['data'] == null) {
            print(
                '⚠️ BackendService: Followers data is null, returning empty list');
            return [];
          }
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception("Failed to get followers: ${data['message']}");
        }
      } else {
        throw Exception(
            "Failed to get followers: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Error getting followers: $e');
      // Return empty list instead of throwing error for better UX
      print('⚠️ BackendService: Returning empty followers list due to error');
      return [];
    }
  }

  /// Get user's following
  Future<List<Map<String, dynamic>>> getUserFollowing(String userId,
      {int page = 1, int limit = 20}) async {
    final url = "$baseUrl/api/users/$userId/following?page=$page&limit=$limit";
    print('🔗 BackendService: Getting following for user: $userId');

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Following response - Status: ${response.statusCode}, Body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ BackendService: Successfully got following');
          // Handle case where data might be null or undefined
          if (data['data'] == null) {
            print(
                '⚠️ BackendService: Following data is null, returning empty list');
            return [];
          }
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception("Failed to get following: ${data['message']}");
        }
      } else {
        throw Exception(
            "Failed to get following: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Error getting following: $e');
      // Return empty list instead of throwing error for better UX
      print('⚠️ BackendService: Returning empty following list due to error');
      return [];
    }
  }

  /// Follow/unfollow a user (LEGACY - kept for backward compatibility)
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    final url = "$baseUrl/api/users/follow";
    print(
        '🔗 BackendService: Toggling follow: $currentUserId -> $targetUserId');

    final response = await SimpleHttpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "currentUserId": currentUserId,
        "targetUserId": targetUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data['following'] as bool? ?? false;
    } else {
      throw Exception("Failed to toggle follow: ${response.data}");
    }
  }

  /// Get user profile with posts (NEW EFFICIENT API)
  Future<ProfileData> getUserProfile(String userId,
      {String? currentUserId}) async {
    final url =
        "$baseUrl/api/users/$userId/profile${currentUserId != null ? '?currentUserId=$currentUserId' : ''}";
    print('🔗 BackendService: Getting user profile from: $url');
    print(
        '🔍 BackendService: User ID: $userId, Current User ID: $currentUserId');

    // Test connection first
    print('🔍 BackendService: Testing connection to backend...');
    final connectionTest = await testConnection();
    if (!connectionTest) {
      print('❌ BackendService: Primary URL failed, trying alternatives...');
      final workingUrl = await findWorkingBackendUrl();
      if (workingUrl == null) {
        throw Exception(
            'Cannot connect to backend server. Please check your network connection and ensure the backend is running.');
      }
      print('✅ BackendService: Using alternative URL: $workingUrl');
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Get user profile response - Status: ${response.statusCode}');
      print('📡 BackendService: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 BackendService: Parsed data: $data');

        if (data['success'] == true && data['data'] != null) {
          final profileData = ProfileData.fromJson(data['data']);
          print('✅ BackendService: Successfully parsed profile data');
          print(
              '🔍 BackendService: User: ${profileData.user.displayName}, Posts: ${profileData.posts.length}');
          return profileData;
        } else {
          throw Exception("Invalid response format: ${response.data}");
        }
      } else {
        print(
            '❌ BackendService: HTTP error ${response.statusCode}: ${response.data}');
        throw Exception(
            "Failed to get user profile: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Get user profile error: $e');
      rethrow;
    }
  }

  /// Get posts by a specific user (LEGACY - kept for backward compatibility)
  Future<List<Post>> getUserPosts(String userId,
      {int limit = 20, int offset = 0, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/user/$userId?limit=$limit&offset=$offset${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";
    print('🔗 BackendService: Getting user posts from: $url');
    print(
        '🔍 BackendService: User ID: $userId, Current User ID: $currentUserId');

    // Test connection first
    print('🔍 BackendService: Testing connection to backend...');
    final connectionTest = await testConnection();
    if (!connectionTest) {
      print('❌ BackendService: Primary URL failed, trying alternatives...');
      final workingUrl = await findWorkingBackendUrl();
      if (workingUrl == null) {
        throw Exception(
            'Cannot connect to backend server. Please check your network connection and ensure the backend is running.');
      }
      print('✅ BackendService: Using alternative URL: $workingUrl');
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print(
          '📡 BackendService: Get user posts response - Status: ${response.statusCode}');
      print('📡 BackendService: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 BackendService: Parsed data: $data');

        // Check if data is null or empty
        if (data == null) {
          print('❌ BackendService: Data is null');
          return [];
        }

        // Check for posts in either 'data' or 'posts' field (backend compatibility)
        List<dynamic>? postsList;
        if (data.containsKey('data')) {
          postsList = data['data'] as List<dynamic>?;
          print('🔍 BackendService: Found posts in "data" field');
        } else if (data.containsKey('posts')) {
          postsList = data['posts'] as List<dynamic>?;
          print('🔍 BackendService: Found posts in "posts" field');
        } else {
          print('❌ BackendService: No "data" or "posts" field in response');
          print('🔍 BackendService: Available keys: ${data.keys.toList()}');
          return [];
        }
        print('🔍 BackendService: Posts list: $postsList');

        if (postsList == null) {
          print('❌ BackendService: Posts list is null');
          return [];
        }

        if (postsList.isEmpty) {
          print('✅ BackendService: Posts list is empty (no posts found)');
          return [];
        }

        final posts = postsList
            .map((post) {
              print('🔍 BackendService: Processing post: $post');
              try {
                return Post.fromJson(post);
              } catch (e) {
                print('❌ BackendService: Error parsing post: $e');
                print('❌ BackendService: Problematic post data: $post');
                return null;
              }
            })
            .where((post) => post != null)
            .cast<Post>()
            .toList();

        print('✅ BackendService: Successfully parsed ${posts.length} posts');
        return posts;
      } else {
        print(
            '❌ BackendService: HTTP error ${response.statusCode}: ${response.data}');
        throw Exception(
            "Failed to get user posts: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print('❌ BackendService: Get user posts error: $e');
      throw Exception("Failed to get user posts: $e");
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId, {String? userId}) async {
    final url = "$baseUrl/api/posts/$postId";
    print('🔗 BackendService: Deleting post: $postId with userId: $userId');

    // Prepare request body with userId
    final requestBody = userId != null ? jsonEncode({"userId": userId}) : null;
    print('🔍 BackendService: Request body: $requestBody');

    final response = await SimpleHttpClient.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    print(
        '📡 BackendService: Delete response - Status: ${response.statusCode}, Body: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Failed to delete post: ${response.data}");
    }
  }
}

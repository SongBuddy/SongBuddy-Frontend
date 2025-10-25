import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:songbuddy/models/AppUser.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/utils/app_logger.dart';
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
    for (String url in alternativeUrls) {
      try {
        final response = await SimpleHttpClient.get(
          "$url/health",
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          AppLogger.success('Connected to backend: $url', tag: 'Backend');
          return url;
        }
      } catch (e) {
        continue; // Try next URL
      }
    }

    AppLogger.error('No working backend found', tag: 'Backend');
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
      AppLogger.warning('Backend health check failed', tag: 'Backend');
      return false;
    }
  }

  /// Find working backend URL by trying alternatives
  Future<String?> findWorkingBackendUrl() async {
    for (String url in alternativeUrls) {
      try {
        final response = await SimpleHttpClient.get(
          "$url/health",
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          AppLogger.success('Found working backend: $url', tag: 'Backend');
          return url;
        }
      } catch (e) {
        continue; // Try next URL
      }
    }

    AppLogger.error('No working backend URL found', tag: 'Backend');
    return null;
  }

  Future<AppUser?> saveUser(AppUser user) async {
    final url = "$baseUrl/api/users/save";

    try {
      final response = await _httpClient.post(
        url,
        data: user.toJson(),
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.success('User saved: ${user.displayName}', tag: 'Backend');
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
      AppLogger.error('Failed to save user', error: e, tag: 'Backend');
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

  /// Update currently playing data for a user
  Future<bool> updateCurrentlyPlaying(String userId, Map<String, dynamic>? currentlyPlaying) async {
    try {
      final updates = {
        'currentlyPlaying': currentlyPlaying,
      };

      final result = await updateUser(userId, updates);

      if (result != null) {
        return true;
      } else {
        AppLogger.warning('Failed to update currently playing', tag: 'Backend');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error updating currently playing', error: e, tag: 'Backend');
      return false;
    }
  }

  /// Delete user from backend
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await SimpleHttpClient.delete(
        "$baseUrl/api/users/$userId",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Connection": "keep-alive",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.success('User deleted: $userId', tag: 'Backend');
        return true;
      } else {
        throw Exception(
            "Failed to delete user: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.error('Failed to delete user', error: e, tag: 'Backend');

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
    final postJson = post.toJson();

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

      if (response.statusCode == 201) {
        final data = response.data;

        try {
          final createdPost = Post.fromJson(data);
          AppLogger.success('Post created: ${post.songName}', tag: 'Backend');
          return createdPost;
        } catch (e) {
          AppLogger.error('Failed to parse post response', error: e, tag: 'Backend');
          throw Exception("Failed to parse post data from backend: $e");
        }
      } else {
        throw Exception(
            "Failed to create post: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.error('Failed to create post', error: e, tag: 'Backend');

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

    final response = await SimpleHttpClient.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final posts = (data['posts'] as List<dynamic>? ?? [])
          .map((post) => Post.fromJson(post))
          .toList();
      AppLogger.debug('Loaded ${posts.length} following posts', tag: 'Backend');
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

    final response = await _httpClient.get(
      url,
      options: Options(
        headers: {"Content-Type": "application/json"},
        // Allow longer response time for hosted backends with cold starts
        receiveTimeout: const Duration(seconds: 75),
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;

      // Check different possible response structures
      List<dynamic> postsList = [];

      if (data['posts'] != null) {
        postsList = data['posts'] as List<dynamic>;
      } else if (data['data'] != null) {
        postsList = data['data'] as List<dynamic>;
      } else if (data is List) {
        postsList = data;
      } else {
        AppLogger.warning('No posts found in feed response', tag: 'Backend');
        return [];
      }

      final posts = postsList.map((post) => Post.fromJson(post)).toList();
      AppLogger.info('Loaded ${posts.length} feed posts', tag: 'Backend');
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

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      // Handle no results (404)
      if (response.statusCode == 404) {
        return [];
      }

      // Handle successful response
      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['data'] is List) {
          final users = List<Map<String, dynamic>>.from(data['data']);
          AppLogger.debug('Found ${users.length} users for "$query"', tag: 'Backend');
          return users;
        }
      }

      throw Exception('Unexpected response format: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('User search failed', error: e, tag: 'Backend');
      return [];
    }
  }

  /// Get discovery posts (Instagram-style) from users not followed
  Future<List<Map<String, dynamic>>> getDiscoveryPosts(
      {String? userId, int page = 1, int limit = 20}) async {
    final url =
        "$baseUrl/api/posts/discovery?userId=${Uri.encodeComponent(userId ?? '')}&page=$page&limit=$limit";

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['data'] is List) {
          final posts = List<Map<String, dynamic>>.from(data['data']);
          AppLogger.debug('Found ${posts.length} discovery posts', tag: 'Backend');
          return posts;
        }
      }

      throw Exception('Unexpected response format: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Discovery posts failed', error: e, tag: 'Backend');
      return [];
    }
  }

  /// Search posts by song name, artist, or description
  Future<List<Post>> searchPosts(String query,
      {int page = 1, int limit = 20, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final posts = (data['data'] as List<dynamic>)
              .map((post) => Post.fromJson(post))
              .toList();
          AppLogger.debug('Found ${posts.length} posts for "$query"', tag: 'Backend');
          return posts;
        } else {
          return [];
        }
      } else {
        throw Exception(
            "Failed to search posts: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.error('Post search failed', error: e, tag: 'Backend');
      throw Exception("Failed to search posts: $e");
    }
  }

  /// Like a post
  Future<bool> likePost(String postId, String userId) async {
    final url = "$baseUrl/api/posts/$postId/like";

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

    final response = await SimpleHttpClient.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "description": description,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      AppLogger.success('Post updated: $postId', tag: 'Backend');
      return Post.fromJson(data);
    } else {
      throw Exception("Failed to update post: ${response.data}");
    }
  }

  /// Follow a user
  Future<Map<String, dynamic>> followUser(
      String currentUserId, String targetUserId) async {
    final url = "$baseUrl/api/users/$targetUserId/follow";

    final response = await SimpleHttpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "followerId": currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        AppLogger.info('Followed user: $targetUserId', tag: 'Backend');
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

    final response = await SimpleHttpClient.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "followerId": currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        AppLogger.info('Unfollowed user: $targetUserId', tag: 'Backend');
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

    final response = await SimpleHttpClient.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
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
      {int page = 1, int limit = 20, String? currentUserId}) async {
    String url = "$baseUrl/api/users/$userId/followers?page=$page&limit=$limit";
    if (currentUserId != null) {
      url += "&currentUserId=$currentUserId";
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          if (data['data'] == null) {
            return [];
          }
          final followers = List<Map<String, dynamic>>.from(data['data']);
          AppLogger.debug('Loaded ${followers.length} followers', tag: 'Backend');
          return followers;
        } else {
          throw Exception("Failed to get followers: ${data['message']}");
        }
      } else {
        throw Exception(
            "Failed to get followers: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.warning('Error getting followers', tag: 'Backend');
      return [];
    }
  }

  /// Get user's following
  Future<List<Map<String, dynamic>>> getUserFollowing(String userId,
      {int page = 1, int limit = 20, String? currentUserId}) async {
    String url = "$baseUrl/api/users/$userId/following?page=$page&limit=$limit";
    if (currentUserId != null) {
      url += "&currentUserId=$currentUserId";
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          if (data['data'] == null) {
            return [];
          }
          final following = List<Map<String, dynamic>>.from(data['data']);
          AppLogger.debug('Loaded ${following.length} following', tag: 'Backend');
          return following;
        } else {
          throw Exception("Failed to get following: ${data['message']}");
        }
      } else {
        throw Exception(
            "Failed to get following: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.warning('Error getting following', tag: 'Backend');
      return [];
    }
  }

  /// Follow/unfollow a user (LEGACY - kept for backward compatibility)
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    final url = "$baseUrl/api/users/follow";

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

    // Test connection first
    final connectionTest = await testConnection();
    if (!connectionTest) {
      final workingUrl = await findWorkingBackendUrl();
      if (workingUrl == null) {
        throw Exception(
            'Cannot connect to backend server. Please check your network connection and ensure the backend is running.');
      }
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final profileData = ProfileData.fromJson(data['data']);
          AppLogger.info('Loaded profile: ${profileData.user.displayName} (${profileData.posts.length} posts)', tag: 'Backend');
          return profileData;
        } else {
          throw Exception("Invalid response format: ${response.data}");
        }
      } else {
        throw Exception(
            "Failed to get user profile: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.error('Failed to get user profile', error: e, tag: 'Backend');
      rethrow;
    }
  }

  /// Get posts by a specific user (LEGACY - kept for backward compatibility)
  Future<List<Post>> getUserPosts(String userId,
      {int limit = 20, int offset = 0, String? currentUserId}) async {
    final url =
        "$baseUrl/api/posts/user/$userId?limit=$limit&offset=$offset${currentUserId != null ? '&currentUserId=$currentUserId' : ''}";

    // Test connection first
    final connectionTest = await testConnection();
    if (!connectionTest) {
      final workingUrl = await findWorkingBackendUrl();
      if (workingUrl == null) {
        throw Exception(
            'Cannot connect to backend server. Please check your network connection and ensure the backend is running.');
      }
    }

    try {
      final response = await SimpleHttpClient.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if data is null or empty
        if (data == null) {
          return [];
        }

        // Check for posts in either 'data' or 'posts' field (backend compatibility)
        List<dynamic>? postsList;
        if (data.containsKey('data')) {
          postsList = data['data'] as List<dynamic>?;
        } else if (data.containsKey('posts')) {
          postsList = data['posts'] as List<dynamic>?;
        } else {
          return [];
        }

        if (postsList == null || postsList.isEmpty) {
          return [];
        }

        final posts = postsList
            .map((post) {
              try {
                return Post.fromJson(post);
              } catch (e) {
                AppLogger.warning('Error parsing post', tag: 'Backend');
                return null;
              }
            })
            .where((post) => post != null)
            .cast<Post>()
            .toList();

        AppLogger.debug('Loaded ${posts.length} user posts', tag: 'Backend');
        return posts;
      } else {
        throw Exception(
            "Failed to get user posts: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      AppLogger.error('Failed to get user posts', error: e, tag: 'Backend');
      throw Exception("Failed to get user posts: $e");
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId, {String? userId}) async {
    final url = "$baseUrl/api/posts/$postId";

    // Prepare request body with userId
    final requestBody = userId != null ? jsonEncode({"userId": userId}) : null;

    final response = await SimpleHttpClient.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      AppLogger.success('Post deleted: $postId', tag: 'Backend');
      return true;
    } else {
      throw Exception("Failed to delete post: ${response.data}");
    }
  }
}

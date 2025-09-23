import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:songbuddy/models/AppUser.dart';
import 'package:songbuddy/models/Post.dart';
import 'backend_api_service.dart';


class BackendService {
 
  /// Clear any cached backend URLs to force rediscovery
  static void clearCache() {
    BackendApiService.clearBackendCache();
  }

  Future<AppUser?> saveUser(AppUser user) async {
    // Use dynamic backend discovery to get the correct URL
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/users/save";
    print('🔗 BackendService: Attempting to save user to: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
      throw Exception("Failed to save user: ${response.body}");
    }
  }

  /// Update user fields (all fields except id are updatable)
  Future<AppUser?> updateUser(String userId, Map<String, dynamic> updates) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final response = await http.put(
      Uri.parse("$baseUrl/api/users/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
      throw Exception("Failed to update user: ${response.body}");
    }
  }

  /// Delete user from backend
  Future<bool> deleteUser(String userId) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final response = await http.delete(
      Uri.parse("$baseUrl/api/users/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Failed to delete user: ${response.body}");
    }
  }

  /// Get user information from backend
  Future<AppUser?> getUser(String userId) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final response = await http.get(
      Uri.parse("$baseUrl/api/users/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
      throw Exception("Failed to get user: ${response.body}");
    }
  }

  // ===== POST-RELATED METHODS =====

  /// Create a new post
  Future<Post> createPost(Post post) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/posts/create";
    print('🔗 BackendService: Creating post at: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(post.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Post.fromJson(data);
    } else {
      throw Exception("Failed to create post: ${response.body}");
    }
  }

  /// Get posts from users that the current user follows (for home feed)
  Future<List<Post>> getFollowingPosts(String userId, {int limit = 20, int offset = 0}) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/posts/following/$userId?limit=$limit&offset=$offset";
    print('🔗 BackendService: Getting following posts from: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final posts = (data['posts'] as List<dynamic>? ?? [])
          .map((post) => Post.fromJson(post))
          .toList();
      return posts;
    } else {
      throw Exception("Failed to get following posts: ${response.body}");
    }
  }

  /// Get random recent posts (for search/discovery feed)
  Future<List<Post>> getRandomRecentPosts({int limit = 20, int offset = 0}) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/posts/random?limit=$limit&offset=$offset";
    print('🔗 BackendService: Getting random posts from: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final posts = (data['posts'] as List<dynamic>? ?? [])
          .map((post) => Post.fromJson(post))
          .toList();
      return posts;
    } else {
      throw Exception("Failed to get random posts: ${response.body}");
    }
  }

  /// Like/unlike a post
  Future<bool> togglePostLike(String postId, String userId) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/posts/$postId/like";
    print('🔗 BackendService: Toggling like for post: $postId');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['liked'] as bool? ?? false;
    } else {
      throw Exception("Failed to toggle like: ${response.body}");
    }
  }

  /// Follow/unfollow a user
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    final baseUrl = await BackendApiService.getCurrentBackendUrl();
    final url = "$baseUrl/api/users/follow";
    print('🔗 BackendService: Toggling follow: $currentUserId -> $targetUserId');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "currentUserId": currentUserId,
        "targetUserId": targetUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['following'] as bool? ?? false;
    } else {
      throw Exception("Failed to toggle follow: ${response.body}");
    }
  }
}

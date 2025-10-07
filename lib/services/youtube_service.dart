import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Custom exception for YouTube API errors
class YouTubeException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  YouTubeException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => 'YouTubeException: $message (Status: $statusCode)';
}

/// Service class to handle YouTube Data API v3 calls
class YouTubeService {
  static String get _baseUrl => 'https://www.googleapis.com/youtube/v3';

  final http.Client _client;
  String? _clientId;

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  /// Get client ID from environment variables
  String get _clientIdFromEnv {
    _clientId ??= dotenv.env['YOUTUBE_CLIENT_ID'];
    if (_clientId == null) {
      throw YouTubeException(
        'YouTube credentials not found in environment variables. Make sure YOUTUBE_CLIENT_ID is set in .env file.',
      );
    }
    return _clientId!;
  }

  /// Validate that credentials are loaded
  void _validateCredentials() {
    try {
      _clientIdFromEnv; // This will throw if not found
    } catch (e) {
      throw YouTubeException(
        'YouTube credentials not loaded. Make sure YOUTUBE_CLIENT_ID is set in .env file.',
      );
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }

  /// Sign in with Google and get access token
  Future<Map<String, dynamic>> signIn() async {
    try {
      // Get client ID from environment variables
      final String clientId = _clientIdFromEnv;

      // Create GoogleSignIn with conditional clientId usage
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/youtube.readonly',
          'https://www.googleapis.com/auth/youtube.force-ssl',
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
        // Passing clientId/serverClientId on Android causes error 10. Only set on iOS/Web.
        clientId: (Platform.isIOS || kIsWeb) ? clientId : null,
        serverClientId: (Platform.isIOS || kIsWeb) ? clientId : null,
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw YouTubeException('User cancelled Google Sign-In');
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      return {
        'access_token': auth.accessToken,
        'refresh_token': auth.idToken,
        'expires_in': 3600, // 1 hour
        'token_type': 'Bearer',
        'user': {
          'id': account.id,
          'email': account.email,
          'name': account.displayName,
          'photo': account.photoUrl,
        },
      };
    } catch (e) {
      if (e is YouTubeException) rethrow;
      throw YouTubeException('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    _validateCredentials();
    final String clientId = _clientIdFromEnv;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // Only set clientId on iOS/Web
      clientId: (Platform.isIOS || kIsWeb) ? clientId : null,
    );
    await googleSignIn.signOut();
  }

  /// Get current user's profile
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/channels?part=snippet,contentDetails&mine=true',
      accessToken,
    );
  }

  /// Get user's playlists
  Future<Map<String, dynamic>> getUserPlaylists(String accessToken,
      {int maxResults = 25}) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/playlists?part=snippet,contentDetails&mine=true&maxResults=$maxResults',
      accessToken,
    );
  }

  /// Get user's liked videos (equivalent to liked songs)
  Future<Map<String, dynamic>> getLikedVideos(String accessToken,
      {int maxResults = 25}) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/videos?part=snippet,contentDetails&myRating=like&maxResults=$maxResults',
      accessToken,
    );
  }

  /// Get user's subscriptions (channels they follow)
  Future<Map<String, dynamic>> getSubscriptions(String accessToken,
      {int maxResults = 25}) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/subscriptions?part=snippet,contentDetails&mine=true&maxResults=$maxResults',
      accessToken,
    );
  }

  /// Search for videos (for music discovery)
  Future<Map<String, dynamic>> searchVideos(String query, String accessToken,
      {int maxResults = 25}) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/search?part=snippet&q=${Uri.encodeComponent(query)}&type=video&videoCategoryId=10&maxResults=$maxResults',
      accessToken,
    );
  }

  /// Get video details
  Future<Map<String, dynamic>> getVideoDetails(
      String videoId, String accessToken) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/videos?part=snippet,contentDetails,statistics&id=$videoId',
      accessToken,
    );
  }

  /// Get trending music videos
  Future<Map<String, dynamic>> getTrendingMusic(String accessToken,
      {int maxResults = 25}) async {
    _validateCredentials();
    return await _makeAuthenticatedRequest(
      'GET',
      '/videos?part=snippet,contentDetails,statistics&chart=mostPopular&videoCategoryId=10&maxResults=$maxResults',
      accessToken,
    );
  }

  /// Make an authenticated request to YouTube API
  Future<Map<String, dynamic>> _makeAuthenticatedRequest(
    String method,
    String endpoint,
    String accessToken,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          break;
        case 'DELETE':
          response = await _client.delete(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          break;
        default:
          throw YouTubeException('Unsupported HTTP method: $method');
      }

      // Debug endpoint + status code
      print('[YouTube] $method $endpoint -> ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }

        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = response.body.isNotEmpty
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};

        throw YouTubeException(
          errorData['error']?['message'] ?? 'API request failed',
          statusCode: response.statusCode,
          errorType: errorData['error']?['type'],
        );
      }
    } catch (e) {
      if (e is YouTubeException) rethrow;
      throw YouTubeException('Network error: ${e.toString()}');
    }
  }
}

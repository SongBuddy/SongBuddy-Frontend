import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exception for Spotify API errors
class SpotifyException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  SpotifyException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => 'SpotifyException: $message (Status: $statusCode)';
}

/// Service class to handle Spotify Web API calls
class SpotifyService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _authUrl = 'https://accounts.spotify.com/api/token';
  
  // TODO: Replace with your actual Spotify app credentials
  static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String _clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  static const String _redirectUri = 'YOUR_REDIRECT_URI';

  final http.Client _client;

  SpotifyService({http.Client? client}) : _client = client ?? http.Client();

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }

  /// Get authorization URL for OAuth flow
  String getAuthorizationUrl() {
    const String scope = 'user-read-private user-read-email user-read-currently-playing user-read-playback-state user-library-read playlist-read-private';
    
    final Uri authUri = Uri.parse('https://accounts.spotify.com/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _clientId,
        'scope': scope,
        'redirect_uri': _redirectUri,
        'state': _generateRandomString(16),
      },
    );
    
    return authUri.toString();
  }

  /// Exchange authorization code for access token
  Future<String> exchangeCodeForToken(String code) async {
    try {
      final response = await _client.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${_encodeCredentials()}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'] as String;
      } else {
        throw SpotifyException(
          'Failed to exchange code for token',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SpotifyException) rethrow;
      throw SpotifyException('Network error: ${e.toString()}');
    }
  }

  /// Get current user's profile
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    return await _makeAuthenticatedRequest(
      'GET',
      '/me',
      accessToken,
    );
  }

  /// Get user's currently playing track
  Future<Map<String, dynamic>?> getCurrentlyPlaying(String accessToken) async {
    try {
      return await _makeAuthenticatedRequest(
        'GET',
        '/me/player/currently-playing',
        accessToken,
      );
    } catch (e) {
      // Currently playing might return 204 (No Content) if nothing is playing
      if (e is SpotifyException && e.statusCode == 204) {
        return null;
      }
      rethrow;
    }
  }

  /// Get user's playlists
  Future<Map<String, dynamic>> getUserPlaylists(String accessToken, {int limit = 20, int offset = 0}) async {
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/playlists?limit=$limit&offset=$offset',
      accessToken,
    );
  }

  /// Get user's saved tracks (liked songs)
  Future<Map<String, dynamic>> getUserSavedTracks(String accessToken, {int limit = 20, int offset = 0}) async {
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/tracks?limit=$limit&offset=$offset',
      accessToken,
    );
  }

  /// Get user's top tracks
  Future<Map<String, dynamic>> getUserTopTracks(String accessToken, {String timeRange = 'medium_term', int limit = 20}) async {
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/top/tracks?time_range=$timeRange&limit=$limit',
      accessToken,
    );
  }

  /// Get user's top artists
  Future<Map<String, dynamic>> getUserTopArtists(String accessToken, {String timeRange = 'medium_term', int limit = 20}) async {
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/top/artists?time_range=$timeRange&limit=$limit',
      accessToken,
    );
  }

  /// Make an authenticated request to Spotify API
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
          throw SpotifyException('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = response.body.isNotEmpty 
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        
        throw SpotifyException(
          errorData['error']?['message'] ?? 'API request failed',
          statusCode: response.statusCode,
          errorType: errorData['error']?['type'],
        );
      }
    } catch (e) {
      if (e is SpotifyException) rethrow;
      throw SpotifyException('Network error: ${e.toString()}');
    }
  }

  /// Encode client credentials for Basic Auth
  String _encodeCredentials() {
    // ignore: prefer_const_declarations
    final credentials = '$_clientId:$_clientSecret';
    return base64Encode(utf8.encode(credentials));
  }

  /// Generate random string for state parameter
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length]).join();
  }
}

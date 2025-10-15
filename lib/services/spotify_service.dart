import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static String get _baseUrl => dotenv.env['SPOTIFY_API_BASE_URL'] ?? 'https://api.spotify.com/v1';
  static String get _authUrl => dotenv.env['SPOTIFY_AUTH_URL'] ?? 'https://accounts.spotify.com/api/token';
  
  // Get credentials from environment variables
  static String get _clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get _clientSecret => dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
  static String get _redirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? '';

  final http.Client _client;

  SpotifyService({http.Client? client}) : _client = client ?? http.Client();

  /// Validate that required environment variables are set
  void _validateEnvironmentVariables() {
    if (_clientId.isEmpty) {
      throw SpotifyException(
        'SPOTIFY_CLIENT_ID is not set in environment variables. '
        'Please create a .env file with your Spotify app credentials.',
      );
    }
    if (_clientSecret.isEmpty) {
      throw SpotifyException(
        'SPOTIFY_CLIENT_SECRET is not set in environment variables. '
        'Please create a .env file with your Spotify app credentials.',
      );
    }
    if (_redirectUri.isEmpty) {
      throw SpotifyException(
        'SPOTIFY_REDIRECT_URI is not set in environment variables. '
        'Please create a .env file with your Spotify app credentials.',
      );
    }
  }
  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }

  /// Get authorization URL for OAuth flow
  ///
  /// The [state] parameter MUST be a securely generated random string and
  /// will be echoed back by Spotify. It should be validated upon callback.
  String getAuthorizationUrl({required String state}) {
    _validateEnvironmentVariables();
    const String scope = 'user-read-private user-read-email user-read-currently-playing user-read-playback-state user-library-read playlist-read-private user-read-recently-played user-top-read';

    final Uri authUri = Uri.parse('https://accounts.spotify.com/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _clientId,
        'scope': scope,
        'redirect_uri': _redirectUri,
        'state': state,
        'show_dialog': 'true',
      },
    );

    return authUri.toString();
  }

  /// Exchange authorization code for access token
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      _validateEnvironmentVariables();
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
      // Debug
      // Do NOT log secrets; only method, endpoint, and status
      // ignore: avoid_print
      print('[Spotify] POST /api/token -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = response.body.isNotEmpty 
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        
        throw SpotifyException(
          errorData['error_description'] ?? 'Failed to exchange code for token',
          statusCode: response.statusCode,
          errorType: errorData['error'],
        );
      }
    } catch (e) {
      if (e is SpotifyException) rethrow;
      throw SpotifyException('Network error: ${e.toString()}');
    }
  }

  /// Get current user's profile
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me',
      accessToken,
    );
  }

  /// Get user's currently playing track
  Future<Map<String, dynamic>?> getCurrentlyPlaying(String accessToken) async {
    try {
      _validateEnvironmentVariables();
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
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/playlists?limit=$limit&offset=$offset',
      accessToken,
    );
  }

  /// Get user's saved tracks (liked songs)
  Future<Map<String, dynamic>> getUserSavedTracks(String accessToken, {int limit = 20, int offset = 0}) async {
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/tracks?limit=$limit&offset=$offset',
      accessToken,
    );
  }

  /// Get user's top tracks
  Future<Map<String, dynamic>> getUserTopTracks(String accessToken, {String timeRange = 'medium_term', int limit = 20}) async {
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/top/tracks?time_range=$timeRange&limit=$limit',
      accessToken,
    );
  }

  /// Get user's top artists
  Future<Map<String, dynamic>> getUserTopArtists(String accessToken, {String timeRange = 'medium_term', int limit = 20}) async {
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/top/artists?time_range=$timeRange&limit=$limit',
      accessToken,
    );
  }

  /// Get user's recently played tracks
  Future<Map<String, dynamic>> getRecentlyPlayed(String accessToken, {int limit = 20}) async {
    _validateEnvironmentVariables();
    return await _makeAuthenticatedRequest(
      'GET',
      '/me/player/recently-played?limit=$limit',
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

      // Enhanced debugging for token validation
      print('🔍 [Spotify] Making request to: $uri');
      print('🔍 [Spotify] Method: $method');
      print('🔍 [Spotify] Token length: ${accessToken.length}');
      print('🔍 [Spotify] Token preview: ${accessToken.substring(0, 10)}...');
      print('🔍 [Spotify] Base URL: $_baseUrl');

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

      // Debug endpoint + status code (no token)
      // ignore: avoid_print
      print('[Spotify] $method $endpoint -> ${response.statusCode}');
      print('🔍 [Spotify] Response headers: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
       
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = response.body.isNotEmpty 
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        
        // Enhanced error logging for debugging
        print('❌ [Spotify] Error response body: ${response.body}');
        print('❌ [Spotify] Parsed error data: $errorData');
        
        String errorMessage = 'API request failed';
        if (response.statusCode == 403) {
          errorMessage = 'Access forbidden (403). This usually means:\n'
              '1. Invalid or expired access token\n'
              '2. Insufficient permissions in your Spotify app\n'
              '3. Token doesn\'t have required scopes\n'
              '4. Spotify app configuration issue';
        } else if (response.statusCode == 401) {
          errorMessage = 'Unauthorized (401). Token is invalid or expired.';
        } else if (errorData['error']?['message'] != null) {
          errorMessage = errorData['error']['message'];
        }
        
        throw SpotifyException(
          errorMessage,
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

  /// Securely generate a random URL-safe state string
  static String generateSecureState({int numBytes = 16}) {
    final secureRandom = Random.secure();
    final bytes = List<int>.generate(numBytes, (_) => secureRandom.nextInt(256));
    // Base64 URL-safe without padding
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Refresh access token using a refresh token
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${_encodeCredentials()}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );
      // ignore: avoid_print
      print('[Spotify] POST /api/token (refresh) -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = response.body.isNotEmpty
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};

        throw SpotifyException(
          errorData['error_description'] ?? 'Failed to refresh access token',
          statusCode: response.statusCode,
          errorType: errorData['error'],
        );
      }
    } catch (e) {
      if (e is SpotifyException) rethrow;
      throw SpotifyException('Network error: ${e.toString()}');
    }
  }
}

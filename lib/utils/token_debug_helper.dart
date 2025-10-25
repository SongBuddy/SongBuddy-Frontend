import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class to debug token validation issues
class TokenDebugHelper {
  static const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';

  /// Test if a token is valid by making a simple request to Spotify
  static Future<Map<String, dynamic>> testTokenValidity(
      String accessToken) async {
    try {
      print('🔍 [TokenDebug] Testing token validity...');
      print('🔍 [TokenDebug] Token length: ${accessToken.length}');
      print(
          '🔍 [TokenDebug] Token preview: ${accessToken.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('$spotifyApiBaseUrl/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('🔍 [TokenDebug] Response status: ${response.statusCode}');
      print('🔍 [TokenDebug] Response headers: ${response.headers}');
      print('🔍 [TokenDebug] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print(
            '✅ [TokenDebug] Token is valid! User: ${data['display_name']} (${data['id']})');
        return {'valid': true, 'user': data, 'message': 'Token is valid'};
      } else {
        Map<String, dynamic> errorData = <String, dynamic>{};
        try {
          if (response.body.isNotEmpty) {
            errorData = json.decode(response.body) as Map<String, dynamic>;
          }
        } catch (e) {
          print('⚠️ [TokenDebug] Could not parse error response as JSON: $e');
          errorData = {'raw_response': response.body};
        }

        String errorMessage = 'Token validation failed';
        if (response.statusCode == 401) {
          errorMessage = 'Token is invalid or expired (401)';
        } else if (response.statusCode == 403) {
          if (response.body
              .contains('Check settings on developer.spotify.com/dashboard')) {
            errorMessage = 'Spotify app configuration issue (403).\n'
                'SOLUTION:\n'
                '1. Go to https://developer.spotify.com/dashboard\n'
                '2. Check your app is not in "Development Mode" with user restrictions\n'
                '3. Add your test user to "Users and Access" section\n'
                '4. Or switch to "Extended Quota Mode"\n'
                '5. Verify redirect URI: songbuddy://callback';
          } else {
            errorMessage =
                'Access forbidden (403). Check app permissions and scopes';
          }
        } else if (errorData['error']?['message'] != null) {
          errorMessage = errorData['error']['message'];
        }

        print('❌ [TokenDebug] $errorMessage');
        return {
          'valid': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'response': errorData
        };
      }
    } catch (e) {
      print('❌ [TokenDebug] Network error: $e');
      return {
        'valid': false,
        'error': 'Network error: ${e.toString()}',
        'exception': e.toString()
      };
    }
  }

  /// Test environment variables configuration
  static Map<String, dynamic> testEnvironmentConfig() {
    print('🔍 [TokenDebug] Testing environment configuration...');

    final clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
    final redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI'] ?? '';
    final apiBaseUrl = dotenv.env['SPOTIFY_API_BASE_URL'] ?? '';
    final authUrl = dotenv.env['SPOTIFY_AUTH_URL'] ?? '';

    print(
        '🔍 [TokenDebug] Client ID: ${clientId.isNotEmpty ? "✅ Set (${clientId.length} chars)" : "❌ Missing"}');
    print(
        '🔍 [TokenDebug] Client Secret: ${clientSecret.isNotEmpty ? "✅ Set (${clientSecret.length} chars)" : "❌ Missing"}');
    print(
        '🔍 [TokenDebug] Redirect URI: ${redirectUri.isNotEmpty ? "✅ $redirectUri" : "❌ Missing"}');
    print(
        '🔍 [TokenDebug] API Base URL: ${apiBaseUrl.isNotEmpty ? "✅ $apiBaseUrl" : "❌ Missing"}');
    print(
        '🔍 [TokenDebug] Auth URL: ${authUrl.isNotEmpty ? "✅ $authUrl" : "❌ Missing"}');

    return {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'redirectUri': redirectUri,
      'apiBaseUrl': apiBaseUrl,
      'authUrl': authUrl,
      'allConfigured': clientId.isNotEmpty &&
          clientSecret.isNotEmpty &&
          redirectUri.isNotEmpty
    };
  }

  /// Test network connectivity to Spotify
  static Future<Map<String, dynamic>> testNetworkConnectivity() async {
    try {
      print('🔍 [TokenDebug] Testing network connectivity to Spotify...');

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('🔍 [TokenDebug] Network test response: ${response.statusCode}');

      return {
        'reachable': true,
        'statusCode': response.statusCode,
        'message': 'Spotify API is reachable'
      };
    } catch (e) {
      print('❌ [TokenDebug] Network connectivity failed: $e');
      return {
        'reachable': false,
        'error': e.toString(),
        'message': 'Cannot reach Spotify API'
      };
    }
  }
}

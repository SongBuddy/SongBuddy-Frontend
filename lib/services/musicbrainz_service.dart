import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exception for MusicBrainz API errors
class MusicBrainzException implements Exception {
  final String message;
  final int? statusCode;

  MusicBrainzException(this.message, {this.statusCode});

  @override
  String toString() => 'MusicBrainzException: $message (Status: $statusCode)';
}

/// Service class to handle MusicBrainz API calls
class MusicBrainzService {
  static const String _baseUrl = 'https://musicbrainz.org/ws/2';
  final http.Client _client;

  MusicBrainzService({http.Client? client}) : _client = client ?? http.Client();

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }

  /// Make a GET request to MusicBrainz API
  Future<Map<String, dynamic>> _makeRequest(String endpoint, {Map<String, String>? queryParameters}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: {
        ...?queryParameters,
        'fmt': 'json', // Request JSON format
      },
    );

    try {
      final response = await _client.get(uri, headers: {'User-Agent': 'SongBuddyApp/1.0.0 (contact@example.com)'});

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = response.body.isNotEmpty
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};

        throw MusicBrainzException(
          errorData['error'] ?? 'MusicBrainz API request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MusicBrainzException) rethrow;
      throw MusicBrainzException('Network error: ${e.toString()}');
    }
  }

  /// Search for artists
  Future<List<Map<String, dynamic>>> searchArtists(String query, {int limit = 20, int offset = 0}) async {
    final data = await _makeRequest(
      '/artist',
      queryParameters: {'query': query, 'limit': limit.toString(), 'offset': offset.toString()},
    );
    return (data['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Get artist details by MBID
  Future<Map<String, dynamic>> getArtistDetails(String mbid) async {
    return await _makeRequest('/artist/$mbid', queryParameters: {'inc': 'releases+tags+aliases'});
  }

  /// Search for recordings (tracks)
  Future<List<Map<String, dynamic>>> searchRecordings(String query, {int limit = 20, int offset = 0}) async {
    final data = await _makeRequest(
      '/recording',
      queryParameters: {'query': query, 'limit': limit.toString(), 'offset': offset.toString()},
    );
    return (data['recordings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Get recording details by MBID
  Future<Map<String, dynamic>> getRecordingDetails(String mbid) async {
    return await _makeRequest('/recording/$mbid', queryParameters: {'inc': 'artist-credits+releases'});
  }

  /// Search for releases (albums)
  Future<List<Map<String, dynamic>>> searchReleases(String query, {int limit = 20, int offset = 0}) async {
    final data = await _makeRequest(
      '/release',
      queryParameters: {'query': query, 'limit': limit.toString(), 'offset': offset.toString()},
    );
    return (data['releases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Get release details by MBID
  Future<Map<String, dynamic>> getReleaseDetails(String mbid) async {
    return await _makeRequest('/release/$mbid', queryParameters: {'inc': 'recordings+labels'});
  }
}

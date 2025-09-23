import 'package:songbuddy/models/AppUser.dart';

import '../services/spotify_service.dart';
import '../services/backend_service.dart';


class AuthFlow {
  final SpotifyService spotifyService;
  final BackendService backendService;

  AuthFlow(this.spotifyService, this.backendService);

  Future<AppUser> loginAndSave(String accessToken) async {
    try {
      // 1. Get Spotify profile
      final profileJson = await spotifyService.getCurrentUser(accessToken);

      // 2. Get additional user data in parallel
      final futures = await Future.wait([
        spotifyService.getCurrentlyPlaying(accessToken).catchError((e) => null),
        spotifyService.getUserTopArtists(accessToken, limit: 10).catchError((e) => {'items': []}),
        spotifyService.getUserTopTracks(accessToken, limit: 10).catchError((e) => {'items': []}),
        spotifyService.getRecentlyPlayed(accessToken, limit: 10).catchError((e) => {'items': []}),
      ]);

      final currentlyPlaying = futures[0] as Map<String, dynamic>?;
      final topArtistsResponse = futures[1] as Map<String, dynamic>;
      final topTracksResponse = futures[2] as Map<String, dynamic>;
      final recentlyPlayedResponse = futures[3] as Map<String, dynamic>;

      // 3. Extract items from responses
      final topArtists = (topArtistsResponse['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];
      final topTracks = (topTracksResponse['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];
      final recentlyPlayed = (recentlyPlayedResponse['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];

      // 4. Create enhanced user object
      final user = AppUser(
        id: profileJson['id'] ?? '',
        country: profileJson['country'] ?? 'US',
        displayName: profileJson['display_name'] ?? '',
        email: profileJson['email'] ?? '',
        profilePicture: (profileJson['images'] != null && profileJson['images'].isNotEmpty)
            ? profileJson['images'][0]['url'] ?? ''
            : '',
        currentlyPlaying: currentlyPlaying,
        topArtists: topArtists,
        topTracks: topTracks,
        recentlyPlayed: recentlyPlayed,
      );

      // 5. Save user to backend
      final savedUser = await backendService.saveUser(user);

      // 6. Return the saved user (with backend confirmation)
      if (savedUser == null) {
        throw Exception('Failed to save user to backend: received null response');
      }
      return savedUser;
    } catch (e) {
      throw Exception('Failed to collect user data: $e');
    }
  }
}

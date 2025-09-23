import 'package:songbuddy/models/AppUser.dart';

import '../services/spotify_service.dart';
import '../services/backend_service.dart';


class AuthFlow {
  final SpotifyService spotifyService;
  final BackendService backendService;

  AuthFlow(this.spotifyService, this.backendService);

  Future<AppUser> loginAndSave(String accessToken) async {
    // 1. Get Spotify profile
    final profileJson = await spotifyService.getCurrentUser(accessToken);

    // 2. Convert to AppUser model
    final user = AppUser.fromSpotify(profileJson);

    // 3. Save user to backend
    final savedUser = await backendService.saveUser(user);

    // 4. Return the saved user (with backend confirmation)
    if (savedUser == null) {
      throw Exception('Failed to save user to backend: received null response');
    }
    return savedUser;
  }
}

import 'package:url_launcher/url_launcher.dart';

class SpotifyDeepLinkService {
  /// Open a song in Spotify app using deep linking
  static Future<bool> openSongInSpotify({
    required String songName,
    required String artistName,
  }) async {
    try {
      // Create Spotify search URL
      final searchQuery = Uri.encodeComponent('$songName $artistName');
      final spotifyUrl = 'spotify:search:$searchQuery';
      
      print('🔗 SpotifyDeepLinkService: Opening Spotify with query: $searchQuery');
      
      // Try multiple approaches to open Spotify
      final approaches = [
        // Approach 1: Direct Spotify deep link with external application
        () async {
          final spotifyUri = Uri.parse(spotifyUrl);
          return await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
        },
        
        // Approach 2: Try with platform default mode
        () async {
          final spotifyUri = Uri.parse(spotifyUrl);
          return await launchUrl(spotifyUri, mode: LaunchMode.platformDefault);
        },
        
        // Approach 3: Try opening Spotify app first, then search
        () async {
          final spotifyAppUri = Uri.parse('spotify://');
          final launched = await launchUrl(spotifyAppUri, mode: LaunchMode.externalApplication);
          if (launched) {
            // Wait a bit for Spotify to open, then try the search
            await Future.delayed(const Duration(milliseconds: 1000));
            final searchUri = Uri.parse(spotifyUrl);
            return await launchUrl(searchUri, mode: LaunchMode.externalApplication);
          }
          return false;
        },
        
        // Approach 4: Try with different URL format
        () async {
          final alternativeUrl = 'spotify://search:$searchQuery';
          final altUri = Uri.parse(alternativeUrl);
          return await launchUrl(altUri, mode: LaunchMode.externalApplication);
        },
        
        // Approach 5: Try opening Spotify app only
        () async {
          final spotifyAppUri = Uri.parse('spotify://');
          return await launchUrl(spotifyAppUri, mode: LaunchMode.externalApplication);
        },
        
        // Approach 6: Web fallback
        () async {
          final webUrl = 'https://open.spotify.com/search/$searchQuery';
          final webUri = Uri.parse(webUrl);
          return await launchUrl(webUri, mode: LaunchMode.externalApplication);
        },
      ];
      
      // Try each approach
      for (int i = 0; i < approaches.length; i++) {
        try {
          print('🔗 SpotifyDeepLinkService: Trying approach ${i + 1}');
          final success = await approaches[i]();
          if (success) {
            print('✅ SpotifyDeepLinkService: Successfully opened Spotify with approach ${i + 1}');
            return true;
          }
        } catch (e) {
          print('❌ SpotifyDeepLinkService: Approach ${i + 1} failed: $e');
          continue;
        }
      }
      
      print('❌ SpotifyDeepLinkService: All approaches failed');
      return false;
    } catch (e) {
      print('❌ SpotifyDeepLinkService: Error opening Spotify: $e');
      return false;
    }
  }

  /// Open Spotify app directly
  static Future<bool> openSpotifyApp() async {
    try {
      final spotifyUri = Uri.parse('spotify://');
      
      if (await canLaunchUrl(spotifyUri)) {
        final launched = await launchUrl(spotifyUri);
        if (launched) {
          print('✅ SpotifyDeepLinkService: Opened Spotify app');
          return true;
        }
      }
      
      // Fallback to web
      final webUri = Uri.parse('https://open.spotify.com');
      if (await canLaunchUrl(webUri)) {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) {
          print('✅ SpotifyDeepLinkService: Opened Spotify web');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ SpotifyDeepLinkService: Error opening Spotify app: $e');
      return false;
    }
  }

  /// Check if Spotify app is installed
  static Future<bool> isSpotifyInstalled() async {
    try {
      final spotifyUri = Uri.parse('spotify://');
      return await canLaunchUrl(spotifyUri);
    } catch (e) {
      print('❌ SpotifyDeepLinkService: Error checking Spotify installation: $e');
      return false;
    }
  }

  /// Get user-friendly error message for Spotify issues
  static String getSpotifyErrorMessage() {
    return 'Spotify app not found. Please install Spotify from the Play Store or App Store.';
  }

  /// Try to open Spotify with a simple approach first
  static Future<bool> openSpotifySimple() async {
    try {
      print('🔗 SpotifyDeepLinkService: Trying simple Spotify opening');
      final spotifyUri = Uri.parse('spotify://');
      final success = await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
      if (success) {
        print('✅ SpotifyDeepLinkService: Successfully opened Spotify app');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ SpotifyDeepLinkService: Simple Spotify opening failed: $e');
      return false;
    }
  }
}

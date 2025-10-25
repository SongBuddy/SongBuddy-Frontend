import 'package:share_plus/share_plus.dart';
import 'package:songbuddy/models/Post.dart';

/// Utility class for standardized post sharing across the app
class PostSharingUtils {
  /// Generate standardized share text for a post
  static String generateShareText({
    required String songName,
    required String artistName,
    required String username,
    String? description,
  }) {
    final buffer = StringBuffer();

    // Song and artist with emoji
    buffer.writeln('🎵 $songName - $artistName');

    // Posted by user
    buffer.writeln('Posted by $username');

    // Add description if available
    if (description != null && description.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(description.trim());
    }

    // Add app promotion
    buffer.writeln();
    buffer.write('Shared via SongBuddy 🎶');

    return buffer.toString();
  }

  /// Share a post using the Post model
  static void sharePost(Post post) {
    final text = generateShareText(
      songName: post.songName,
      artistName: post.artistName,
      username: post.username,
      description: post.description,
    );

    Share.share(
      text,
      subject: "Check out this song on SongBuddy!",
    );
  }

  /// Share a post using individual parameters (for discovery posts)
  static void sharePostFromData({
    required String songName,
    required String artistName,
    required String username,
    String? description,
  }) {
    final text = generateShareText(
      songName: songName,
      artistName: artistName,
      username: username,
      description: description,
    );

    Share.share(
      text,
      subject: "Check out this song on SongBuddy!",
    );
  }
}

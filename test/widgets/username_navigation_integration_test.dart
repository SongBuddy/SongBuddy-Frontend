import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songbuddy/screens/home_feed_screen.dart';
import 'package:songbuddy/screens/search_feed_screen.dart';
import 'package:songbuddy/widgets/music_post_card.dart';

void main() {
  group('Username Navigation Integration Tests', () {
    testWidgets('MusicPostCard username tap integration', (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: 'test_user',
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: '2h',
              showUserInfo: true,
              onUserTap: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Find and tap the username
      final usernameFinder = find.text('test_user');
      expect(usernameFinder, findsOneWidget);

      await tester.tap(usernameFinder);
      await tester.pump();

      // Verify callback was called
      expect(callbackCalled, isTrue);
    });

    testWidgets('MusicPostCard handles null onUserTap gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: 'test_user',
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: '2h',
              showUserInfo: true,
              onUserTap: null, // Explicitly null
            ),
          ),
        ),
      );

      // Find and tap the username - should not crash
      final usernameFinder = find.text('test_user');
      expect(usernameFinder, findsOneWidget);

      await tester.tap(usernameFinder);
      await tester.pump();

      // Widget should still be displayed without errors
      expect(usernameFinder, findsOneWidget);
    });

    testWidgets('HomeFeedScreen and SearchFeedScreen render without errors', (WidgetTester tester) async {
      // Test HomeFeedScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.text('SongBuddy'), findsOneWidget);

      // Test SearchFeedScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      expect(find.byType(SearchFeedScreen), findsOneWidget);
      expect(find.text('Search users...'), findsOneWidget);
    });

    testWidgets('MusicPostCard displays all required content', (WidgetTester tester) async {
      const testUsername = 'test_user';
      const testTrackTitle = 'Test Song';
      const testArtist = 'Test Artist';
      const testTimeAgo = '2h';
      const testDescription = 'Test description';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: testUsername,
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: testTrackTitle,
              artist: testArtist,
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: testTimeAgo,
              description: testDescription,
              showUserInfo: true,
            ),
          ),
        ),
      );

      // Verify all content is displayed
      expect(find.text(testUsername), findsOneWidget);
      expect(find.text(testTrackTitle), findsOneWidget);
      expect(find.text(testArtist), findsOneWidget);
      expect(find.text(testTimeAgo), findsOneWidget);
      expect(find.text(testDescription), findsOneWidget);
    });

    testWidgets('MusicPostCard username has proper styling', (WidgetTester tester) async {
      const testUsername = 'test_user';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: testUsername,
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: '2h',
              showUserInfo: true,
              onUserTap: () {},
            ),
          ),
        ),
      );

      // Find the username text widget
      final usernameFinder = find.text(testUsername);
      expect(usernameFinder, findsOneWidget);

      // Get the text widget and verify its styling
      final textWidget = tester.widget<Text>(usernameFinder);
      expect(textWidget.style?.color, equals(Colors.white));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(textWidget.style?.fontSize, equals(13.0));
    });

    testWidgets('MusicPostCard handles long usernames with ellipsis', (WidgetTester tester) async {
      const longUsername = 'very_long_username_that_should_be_truncated';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: longUsername,
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: '2h',
              showUserInfo: true,
            ),
          ),
        ),
      );

      // Find the username text widget
      final usernameFinder = find.text(longUsername);
      expect(usernameFinder, findsOneWidget);

      // Get the text widget and verify overflow handling
      final textWidget = tester.widget<Text>(usernameFinder);
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('MusicPostCard shows user info when showUserInfo is true', (WidgetTester tester) async {
      const testUsername = 'test_user';
      const testTimeAgo = '2h';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: testUsername,
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: testTimeAgo,
              showUserInfo: true,
            ),
          ),
        ),
      );

      // Verify both username and time are displayed
      expect(find.text(testUsername), findsOneWidget);
      expect(find.text(testTimeAgo), findsOneWidget);
    });

    testWidgets('MusicPostCard hides user info when showUserInfo is false', (WidgetTester tester) async {
      const testUsername = 'test_user';
      const testTimeAgo = '2h';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicPostCard(
              username: testUsername,
              avatarUrl: 'https://example.com/avatar.jpg',
              trackTitle: 'Test Song',
              artist: 'Test Artist',
              coverUrl: 'https://example.com/cover.jpg',
              timeAgo: testTimeAgo,
              showUserInfo: false,
            ),
          ),
        ),
      );

      // Verify username and time are not displayed
      expect(find.text(testUsername), findsNothing);
      expect(find.text(testTimeAgo), findsNothing);
    });
  });
}

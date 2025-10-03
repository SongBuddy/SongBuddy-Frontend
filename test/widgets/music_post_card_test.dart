import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songbuddy/widgets/music_post_card.dart';

void main() {
  group('MusicPostCard Widget Tests', () {
    testWidgets('MusicPostCard displays username correctly', (WidgetTester tester) async {
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
            ),
          ),
        ),
      );

      // Verify username is displayed
      expect(find.text(testUsername), findsOneWidget);
    });

    testWidgets('MusicPostCard username tap triggers onUserTap callback', (WidgetTester tester) async {
      bool callbackCalled = false;
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
              onUserTap: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Find the username text widget
      final usernameFinder = find.text(testUsername);
      expect(usernameFinder, findsOneWidget);

      // Tap on the username
      await tester.tap(usernameFinder);
      await tester.pump();

      // Verify callback was called
      expect(callbackCalled, isTrue);
    });

    testWidgets('MusicPostCard handles null onUserTap gracefully', (WidgetTester tester) async {
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
              onUserTap: null, // Explicitly null
            ),
          ),
        ),
      );

      // Find the username text widget
      final usernameFinder = find.text(testUsername);
      expect(usernameFinder, findsOneWidget);

      // Tap on the username - should not crash
      await tester.tap(usernameFinder);
      await tester.pump();

      // Widget should still be displayed without errors
      expect(usernameFinder, findsOneWidget);
    });

    testWidgets('MusicPostCard username has proper styling for clickability', (WidgetTester tester) async {
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

    testWidgets('MusicPostCard shows user info when showUserInfo is true', (WidgetTester tester) async {
      const testUsername = 'test_user';
      const testTimeAgo = '2h';
      
      await tester.pumpWidget(
        MaterialApp(
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
        MaterialApp(
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

    testWidgets('MusicPostCard displays all required content', (WidgetTester tester) async {
      const testUsername = 'test_user';
      const testTrackTitle = 'Test Song';
      const testArtist = 'Test Artist';
      const testTimeAgo = '2h';
      const testDescription = 'Test description';
      
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('MusicPostCard handles long usernames with ellipsis', (WidgetTester tester) async {
      const longUsername = 'very_long_username_that_should_be_truncated';
      
      await tester.pumpWidget(
        MaterialApp(
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
  });
}

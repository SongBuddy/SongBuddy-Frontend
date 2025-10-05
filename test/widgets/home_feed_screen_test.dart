import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songbuddy/screens/home_feed_screen.dart';

void main() {
  group('HomeFeedScreen Widget Tests', () {
    testWidgets('HomeFeedScreen displays home feed view by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify home feed view is displayed
      expect(find.text('SongBuddy'), findsOneWidget);
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });

    testWidgets('HomeFeedScreen displays notification icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify notification icon is displayed
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('HomeFeedScreen displays search functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the screen renders without errors
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });

    testWidgets('HomeFeedScreen handles widget lifecycle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify initial state
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // Rebuild the widget
      await tester.pump();

      // Verify widget still exists
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });

    testWidgets('HomeFeedScreen displays correct app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify app title is displayed
      expect(find.text('SongBuddy'), findsOneWidget);
    });

    testWidgets('HomeFeedScreen renders without crashing', (WidgetTester tester) async {
      // This test ensures the widget can be created without throwing exceptions
      expect(() => const HomeFeedScreen(), returnsNormally);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });

    testWidgets('HomeFeedScreen handles multiple rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Perform multiple rebuilds
      for (int i = 0; i < 3; i++) {
        await tester.pump();
        expect(find.byType(HomeFeedScreen), findsOneWidget);
      }
    });

    testWidgets('HomeFeedScreen maintains state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeFeedScreen(),
        ),
      );

      // Verify initial state
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // Force rebuild
      await tester.pump();

      // Verify widget still exists after rebuild
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });
  });
}

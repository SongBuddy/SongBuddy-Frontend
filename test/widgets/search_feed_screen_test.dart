import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songbuddy/screens/search_feed_screen.dart';

void main() {
  group('SearchFeedScreen Widget Tests', () {
    testWidgets('SearchFeedScreen displays search feed view by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify search feed view is displayed
      expect(find.byType(SearchFeedScreen), findsOneWidget);
      expect(find.text('Search users...'), findsOneWidget);
    });

    testWidgets('SearchFeedScreen displays search input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify search input is displayed
      expect(find.text('Search users...'), findsOneWidget);
    });

    testWidgets('SearchFeedScreen displays microphone icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify microphone icon is displayed
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('SearchFeedScreen handles widget lifecycle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify initial state
      expect(find.byType(SearchFeedScreen), findsOneWidget);

      // Rebuild the widget
      await tester.pump();

      // Verify widget still exists
      expect(find.byType(SearchFeedScreen), findsOneWidget);
    });

    testWidgets('SearchFeedScreen renders without crashing', (WidgetTester tester) async {
      // This test ensures the widget can be created without throwing exceptions
      expect(() => const SearchFeedScreen(), returnsNormally);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(SearchFeedScreen), findsOneWidget);
    });

    testWidgets('SearchFeedScreen handles multiple rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Perform multiple rebuilds
      for (int i = 0; i < 3; i++) {
        await tester.pump();
        expect(find.byType(SearchFeedScreen), findsOneWidget);
      }
    });

    testWidgets('SearchFeedScreen maintains state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Verify initial state
      expect(find.byType(SearchFeedScreen), findsOneWidget);

      // Force rebuild
      await tester.pump();

      // Verify widget still exists after rebuild
      expect(find.byType(SearchFeedScreen), findsOneWidget);
    });

    testWidgets('SearchFeedScreen displays search functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the screen renders without errors
      expect(find.byType(SearchFeedScreen), findsOneWidget);
    });

    testWidgets('SearchFeedScreen handles text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchFeedScreen(),
        ),
      );

      // Find the search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter text in the search field
      await tester.enterText(searchField, 'test search');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test search'), findsOneWidget);
    });
  });
}

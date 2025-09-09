import 'package:flutter_test/flutter_test.dart';
import 'package:songbuddy/main.dart';

void main() {
  group('SongBuddy App Tests', () {
    test('App should start without crashing', () {
      // This is a basic test to ensure the app can be instantiated
      expect(() => const MyApp(), returnsNormally);
    });
  });
}

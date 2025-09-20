import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:songbuddy/screens/search_feed_Screen.dart';
import 'package:songbuddy/screens/splash_screen.dart';
import 'package:songbuddy/theme/app_theme.dart';
import 'screens/home_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_auth_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(const SongBuddyApp());
}

class SongBuddyApp extends StatelessWidget {
  const SongBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SongBuddy',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // <- Root widget with bottom nav
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    SearchFeedScreen(),
    ProfileScreen(),
    SettingsScreen(),
    DebugAuthScreen(), // Temporary debug screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

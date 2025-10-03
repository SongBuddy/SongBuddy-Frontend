import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:songbuddy/screens/search_feed_Screen.dart';
import 'package:songbuddy/screens/splash_screen.dart';
import 'package:songbuddy/theme/app_theme.dart';
import 'package:songbuddy/services/http_client_service.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'screens/home_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize HTTP client service
  HttpClientService.instance;
  
  // Initialize auth provider
  await AuthProvider().initialize();

  // Warm up backend (helps hosted backends avoid cold-start delays)
  try {
    final backendService = BackendService();
    await backendService.testConnection();
  } catch (_) {
    // Ignore failures; UI will handle with normal error flow
  }
  
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
  final GlobalKey<HomeFeedScreenState> _homeFeedKey = GlobalKey<HomeFeedScreenState>();
  final GlobalKey<SearchFeedScreenState> _searchFeedKey = GlobalKey<SearchFeedScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();
  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeFeedScreen(key: _homeFeedKey),
      SearchFeedScreen(key: _searchFeedKey),
      ProfileScreen(key: _profileKey),
      SettingsScreen(key: _settingsKey),
    ];
  }

  void _onItemTapped(int index) {
    // If tapping the same tab, scroll to top
    if (_selectedIndex == index) {
      if (index == 0) {
        // Home tab - scroll to top and refresh
        _homeFeedKey.currentState?.scrollToTopAndRefresh();
      } else if (index == 1) {
        // Search tab - scroll to top and refresh
        _searchFeedKey.currentState?.scrollToTopAndRefresh();
      } else if (index == 2) {
        // Profile tab - scroll to top
        _profileKey.currentState?.scrollToTop();
      } else if (index == 3) {
        // Settings tab - scroll to top
        _settingsKey.currentState?.scrollToTop();
      }
    } else {
      // Switch to different tab
      setState(() {
        _selectedIndex = index;
      });
    }
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

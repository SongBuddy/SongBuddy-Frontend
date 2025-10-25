import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songbuddy/screens/search_feed_Screen.dart';
import 'package:songbuddy/screens/splash_screen.dart';
import 'package:songbuddy/theme/app_theme.dart';
import 'package:songbuddy/services/http_client_service.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/widgets/riverpod_connection_overlay.dart';
import 'package:songbuddy/services/simple_lifecycle_manager.dart';
import 'package:songbuddy/utils/app_logger.dart';
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
  
  // Initialize simple lifecycle manager
  await SimpleLifecycleManager.instance.initialize();
  
  // Start sync service if user is authenticated
  final authProvider = AuthProvider();
  if (authProvider.isAuthenticated) {
    await SimpleLifecycleManager.instance.start();
    AppLogger.success('Sync started for authenticated user', tag: 'Main');
  }
  
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
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SongBuddy',
        theme: AppTheme.lightTheme,
        home: const AppWrapper(),
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiverpodConnectionOverlay(
      child: SplashScreen(),
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
  
  late final AuthProvider _authProvider;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // Initialize auth provider
    _authProvider = AuthProvider();
    _authProvider.addListener(_onAuthChanged);
    
    // Start professional sync when main screen loads (user is authenticated)
    SimpleLifecycleManager.instance.start();
    
    _screens = [
      HomeFeedScreen(key: _homeFeedKey),
      SearchFeedScreen(key: _searchFeedKey),
      ProfileScreen(key: _profileKey),
      SettingsScreen(key: _settingsKey),
    ];
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    SimpleLifecycleManager.instance.stop();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      // Stop professional sync when user logs out
      SimpleLifecycleManager.instance.stop();
    } else {
      // Start professional sync when user logs in
      SimpleLifecycleManager.instance.start();
    }
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
    return const RiverpodConnectionOverlay(
      child: MainScreenContent(),
    );
  }
}

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  State<MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
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

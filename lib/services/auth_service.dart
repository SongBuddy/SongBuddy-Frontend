import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'spotify_service.dart';
import 'package:songbuddy/models/AppUser.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/services/AuthFlow.dart';

/// Authentication state enum
enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Authentication service to handle Spotify OAuth flow
class AuthService extends ChangeNotifier {
  static const String _accessTokenKey = 'spotify_access_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _expiresAtKey = 'spotify_expires_at';
  static const String _userIdKey = 'spotify_user_id';
  static const String _oauthStateKey = 'spotify_oauth_state';

  final SpotifyService _spotifyService;
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<Uri>? _linkSubscription;

  AuthState _state = AuthState.unauthenticated;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _userId;
  String? _errorMessage;
  AppUser? _appUser;
  bool _loadingUserData = false;

  AuthService({
    SpotifyService? spotifyService,
    FlutterSecureStorage? secureStorage,
  })  : _spotifyService = spotifyService ?? SpotifyService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initializeAuth();
  }

  // Getters
  AuthState get state => _state;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get expiresAt => _expiresAt;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _accessToken != null;
  AppUser? get appUser => _appUser;
  bool get isLoadingUserData => _loadingUserData;

  /// Initialize authentication state from stored tokens
  Future<void> _initializeAuth() async {
    try {
      final storedToken = await _secureStorage.read(key: _accessTokenKey);
      final storedExpiresAt = await _secureStorage.read(key: _expiresAtKey);
      final storedUserId = await _secureStorage.read(key: _userIdKey);

      if (storedToken != null && storedExpiresAt != null) {
        final expiresAt = DateTime.parse(storedExpiresAt);

        if (expiresAt.isAfter(DateTime.now())) {
          _accessToken = storedToken;
          _expiresAt = expiresAt;
          _userId = storedUserId;
          _state = AuthState.authenticated;
          notifyListeners();
          // Load user data and wait for it to complete
          await _loadUserData();
          return;
        } else {
          // Token expired, try to refresh
          await _refreshTokenIfNeeded();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }

    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return true; // Assume connected if check fails
    }
  }

  /// Start the Spotify OAuth flow
  Future<void> login() async {
    if (_state == AuthState.authenticating) return;

    try {
      _state = AuthState.authenticating;
      _errorMessage = null;
      notifyListeners();

      // Check internet connectivity first
      final hasInternet = await _checkConnectivity();
      if (!hasInternet) {
        throw Exception(
            'No internet connection. Please check your network and try again.');
      }

      // Generate and persist secure state
      final stateParam = SpotifyService.generateSecureState();
      await _secureStorage.write(key: _oauthStateKey, value: stateParam);

      // Attach deep link listener BEFORE launching the URL to avoid race conditions
      _setupDeepLinkListener();

      // Generate authorization URL with state
      final authUrl = _spotifyService.getAuthorizationUrl(state: stateParam);
      debugPrint('Generated auth URL: $authUrl');

      // Launch the authorization URL
      final uri = Uri.parse(authUrl);

      // Use external application mode to open in browser
      bool launched = false;
      try {
        // Primary: external app (browser)
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('External application launch: $launched');
        if (!launched) {
          // Fallback: in-app webview
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration:
                const WebViewConfiguration(enableJavaScript: true),
          );
          debugPrint('In-app webview launch: $launched');
        }
        if (!launched) {
          // Last resort: platform default
          launched = await launchUrl(uri);
          debugPrint('Default launch: $launched');
        }
      } catch (e) {
        debugPrint('URL launch failed: $e');
      }

      if (!launched) {
        throw Exception(
            'Could not open Spotify authorization page. Install or enable a web browser, or try again later.');
      }

      debugPrint('URL launched successfully');

      // Set a timeout for the authentication process
      Timer(const Duration(minutes: 5), () {
        if (_state == AuthState.authenticating) {
          _state = AuthState.error;
          _errorMessage = 'Authentication timed out. Please try again.';
          notifyListeners();
          _linkSubscription?.cancel();
        }
      });
    } catch (e) {
      debugPrint('Login error: $e');
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Set up deep link listener for OAuth callback
  void _setupDeepLinkListener() {
    _linkSubscription?.cancel();

    _linkSubscription = const EventChannel('songbuddy/oauth')
        .receiveBroadcastStream()
        .map((dynamic event) => Uri.parse(event as String))
        .listen(_handleOAuthCallback);
  }

  /// Public method for testing deep link handling
  Future<void> testHandleOAuthCallback(Uri uri) async {
    await _handleOAuthCallback(uri);
  }

  /// Handle OAuth callback from deep link
  Future<void> _handleOAuthCallback(Uri uri) async {
    debugPrint('Deep link received: $uri');
    try {
      if (uri.scheme == 'songbuddy' && uri.host == 'callback') {
        debugPrint('Processing Spotify callback...');
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        final errorDescription = uri.queryParameters['error_description'];
        final state = uri.queryParameters['state'];

        debugPrint(
            'Callback parameters - code: ${code != null ? "present" : "missing"}, error: $error');

        // Validate state parameter to prevent CSRF
        final expectedState = await _secureStorage.read(key: _oauthStateKey);
        await _secureStorage.delete(key: _oauthStateKey);
        if (expectedState == null || state == null || state != expectedState) {
          throw Exception('Invalid OAuth state. Please try again.');
        }

        if (error != null) {
          final errorMsg = errorDescription ?? error;
          debugPrint('OAuth error received: $errorMsg');
          if (error == 'access_denied') {
            throw Exception(
                'You denied access. Please grant permissions to continue.');
          }
          throw Exception('OAuth error: $errorMsg');
        }

        if (code == null) {
          debugPrint('No authorization code received');
          throw Exception('No authorization code received from Spotify');
        }

        debugPrint('Exchanging code for token...');
        // Exchange code for token
        await _exchangeCodeForToken(code);
      } else {
        debugPrint(
            'Received non-Spotify deep link: ${uri.scheme}://${uri.host}');
      }
    } catch (e) {
      debugPrint('Error in OAuth callback: $e');
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _linkSubscription?.cancel();
    }
  }

  /// Exchange authorization code for access token
  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final tokenResponse = await _spotifyService.exchangeCodeForToken(code);

      // Parse token response
      _accessToken = tokenResponse['access_token'] as String?;
      _refreshToken = tokenResponse['refresh_token'] as String?;

      // Calculate expiration time
      final expiresIn = tokenResponse['expires_in'] as int?;
      if (expiresIn != null) {
        _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      } else {
        // Default to 1 hour if expires_in is not provided
        _expiresAt = DateTime.now().add(const Duration(hours: 1));
      }

      if (_accessToken == null) {
        throw Exception('No access token received from Spotify');
      }

      // Validate token by getting user info
      try {
        final userInfo = await _spotifyService.getCurrentUser(_accessToken!);
        _userId = userInfo['id'] as String?;

        if (_userId == null) {
          throw Exception('Unable to retrieve user information from Spotify');
        }
      } catch (e) {
        // If we can't get user info, the token might be invalid
        throw Exception('Token validation failed: ${e.toString()}');
      }

      // Store tokens securely
      await _storeTokens();

      // After successful Spotify auth, fetch profile and save to backend
      try {
        debugPrint('Attempting to save user to backend...');
        final backendService = BackendService();
        // Initialize the backend service with auth service for token management
        backendService.initializeAuth(this);
        final authFlow = AuthFlow(_spotifyService, backendService);
        _appUser = await authFlow.loginAndSave(_accessToken!);
        debugPrint('✅ User successfully saved to backend!');

        // Ensure user data is properly loaded
        if (_appUser == null) {
          debugPrint(
              '⚠️ AppUser is null after backend save, loading from Spotify...');
          await _loadUserData();
        }
      } catch (e) {
        // Backend save failure - fallback to loading user data directly from Spotify
        debugPrint('❌ Backend save failed: $e');
        debugPrint(
            '🔄 Falling back to loading user data directly from Spotify...');

        try {
          // Load user data directly from Spotify as fallback
          await _loadUserData();
          debugPrint('✅ User data loaded from Spotify as fallback');
        } catch (spotifyError) {
          debugPrint('❌ Failed to load user data from Spotify: $spotifyError');

          String errorMessage;
          if (e.toString().contains('Connection refused') ||
              e.toString().contains('Failed to connect')) {
            errorMessage =
                'Backend server is not running. Please start your backend server on localhost:3000';
          } else if (e.toString().contains('404')) {
            errorMessage =
                'Backend endpoint not found. Check if /api/users/save exists';
          } else if (e.toString().contains('500')) {
            errorMessage = 'Backend server error. Check your backend logs';
          } else {
            errorMessage = 'Backend connection failed: ${e.toString()}';
          }

          _state = AuthState.error;
          _errorMessage = errorMessage;
          notifyListeners();
          return;
        }
      }

      _state = AuthState.authenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = _friendlyMessage(e);
      notifyListeners();
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens() async {
    if (_accessToken != null) {
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken!);
    }
    if (_refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken!);
    }
    if (_expiresAt != null) {
      await _secureStorage.write(
          key: _expiresAtKey, value: _expiresAt!.toIso8601String());
    }
    if (_userId != null) {
      await _secureStorage.write(key: _userIdKey, value: _userId!);
    }
  }

  /// Public method to refresh token if needed (called by HTTP interceptor)
  Future<void> refreshTokenIfNeeded() async {
    await _refreshTokenIfNeeded();
  }

  /// Refresh access token if needed
  Future<void> _refreshTokenIfNeeded() async {
    try {
      // No token or not expired yet
      if (_expiresAt == null || _accessToken == null) {
        // Try loading from storage first
        final storedToken = await _secureStorage.read(key: _accessTokenKey);
        final storedExpiresAt = await _secureStorage.read(key: _expiresAtKey);
        final storedRefresh = await _secureStorage.read(key: _refreshTokenKey);
        if (storedToken != null && storedExpiresAt != null) {
          _accessToken = storedToken;
          _expiresAt = DateTime.tryParse(storedExpiresAt);
        }
        _refreshToken = storedRefresh;
      }

      if (_expiresAt != null &&
          _expiresAt!.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
        // Token still valid
        return;
      }

      if (_refreshToken == null) {
        await logout();
        return;
      }

      final response = await _spotifyService.refreshAccessToken(_refreshToken!);

      final newAccessToken = response['access_token'] as String?;
      final newExpiresIn = response['expires_in'] as int?;
      final maybeNewRefreshToken = response['refresh_token']
          as String?; // Spotify may not always return this

      if (newAccessToken == null) {
        throw Exception('Failed to refresh access token');
      }

      _accessToken = newAccessToken;
      if (newExpiresIn != null) {
        _expiresAt = DateTime.now().add(Duration(seconds: newExpiresIn));
      }
      if (maybeNewRefreshToken != null && maybeNewRefreshToken.isNotEmpty) {
        _refreshToken = maybeNewRefreshToken;
      }

      await _storeTokens();

      _state = AuthState.authenticated;
      notifyListeners();
      debugPrint('✅ Token refreshed successfully');
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      // Don't automatically logout here - let the calling code decide
      // This allows for better error handling in different contexts
      rethrow;
    }
  }

  String _friendlyMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('No internet connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('access_denied')) {
      return 'You denied access. Grant permissions to continue.';
    }
    if (msg.contains('browser') || msg.contains('authorization page')) {
      return 'Could not open the authorization page. Install or enable a browser.';
    }
    if (msg.contains('state') && msg.contains('Invalid')) {
      return 'Security check failed. Please try logging in again.';
    }
    return msg;
  }

  /// Logout user and clear stored tokens
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('Error clearing stored tokens: $e');
    }

    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _userId = null;
    _appUser = null;
    _errorMessage = null;
    _state = AuthState.unauthenticated;

    notifyListeners();
  }

  /// Delete user account and logout
  Future<void> deleteAccount() async {
    try {
      // Delete user from backend if we have user info
      if (_userId != null) {
        try {
          final backendService = BackendService();
          await backendService.deleteUser(_userId!);
          debugPrint('✅ User account deleted from backend');
        } catch (e) {
          debugPrint('⚠️ Failed to delete user from backend: $e');
          // Continue with account deletion even if backend deletion fails
        }
      }

      // Clear all stored data
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('Error during account deletion: $e');
    }

    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _userId = null;
    _appUser = null;
    _errorMessage = null;
    _state = AuthState.unauthenticated;

    notifyListeners();
  }

  /// Load user data directly from Spotify
  Future<void> _loadUserData() async {
    if (_accessToken == null) return;

    _loadingUserData = true;
    notifyListeners();

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Get user data directly from Spotify API
        final spotifyUserData =
            await _spotifyService.getCurrentUser(_accessToken!);

        // Create AppUser from Spotify data
        _appUser = AppUser(
          id: spotifyUserData['id'] ?? '',
          country: spotifyUserData['country'] ?? 'US',
          displayName: spotifyUserData['display_name'] ?? '',
          email: spotifyUserData['email'] ?? '',
          profilePicture: (spotifyUserData['images'] != null &&
                  spotifyUserData['images'].isNotEmpty)
              ? spotifyUserData['images'][0]['url'] ?? ''
              : '',
        );

        debugPrint('✅ User data loaded from Spotify: ${_appUser!.displayName}');
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        debugPrint(
            'Failed to load user data from Spotify (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
    }

    _loadingUserData = false;
    notifyListeners();
  }

  /// Manually load user data (public method)
  Future<void> loadUserData() async {
    await _loadUserData();
  }

  /// Force refresh user data (useful after login)
  Future<void> refreshUserData() async {
    if (_accessToken == null) return;

    debugPrint('🔄 Force refreshing user data...');
    await _loadUserData();
  }

  /// Clear error state
  void clearError() {
    if (_state == AuthState.error) {
      _errorMessage = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'spotify_service.dart';

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

  final SpotifyService _spotifyService;
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<Uri>? _linkSubscription;

  AuthState _state = AuthState.unauthenticated;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _userId;
  String? _errorMessage;

  AuthService({
    SpotifyService? spotifyService,
    FlutterSecureStorage? secureStorage,
  }) : _spotifyService = spotifyService ?? SpotifyService(),
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
  bool get isAuthenticated => _state == AuthState.authenticated && _accessToken != null;

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
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Generate authorization URL
      final authUrl = _spotifyService.getAuthorizationUrl();
      debugPrint('Generated auth URL: $authUrl');
      
      // Launch the authorization URL
      final uri = Uri.parse(authUrl);
      
      // Use external application mode to open in browser
      bool launched = false;
      try {
        launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        debugPrint('External application launch: $launched');
      } catch (e) {
        debugPrint('External application launch failed: $e');
      }
      
      if (!launched) {
        throw Exception('Could not open Spotify authorization page. Please check your internet connection and ensure you have a web browser installed.');
      }
      
      debugPrint('URL launched successfully');
      
      // Wait a moment for the browser to open, then set up deep link listener
      await Future.delayed(const Duration(seconds: 2));
      _setupDeepLinkListener();
      
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

        debugPrint('Callback parameters - code: ${code != null ? "present" : "missing"}, error: $error');

        if (error != null) {
          final errorMsg = errorDescription ?? error;
          debugPrint('OAuth error received: $errorMsg');
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
        debugPrint('Received non-Spotify deep link: ${uri.scheme}://${uri.host}');
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

      _state = AuthState.authenticated;
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
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
      await _secureStorage.write(key: _expiresAtKey, value: _expiresAt!.toIso8601String());
    }
    if (_userId != null) {
      await _secureStorage.write(key: _userIdKey, value: _userId!);
    }
  }

  /// Refresh access token if needed
  Future<void> _refreshTokenIfNeeded() async {
    // TODO: Implement token refresh logic
    // For now, just clear the expired token
    await logout();
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
    _errorMessage = null;
    _state = AuthState.unauthenticated;
    
    notifyListeners();
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

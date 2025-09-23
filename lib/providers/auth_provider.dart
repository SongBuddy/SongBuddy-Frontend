import 'package:flutter/material.dart';
import 'package:songbuddy/models/AppUser.dart';
import '../services/auth_service.dart';

/// Global authentication provider that can be used throughout the app
class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal();

  late final AuthService _authService;
  bool _initialized = false;

  /// Initialize the auth provider
  Future<void> initialize() async {
    if (_initialized) return;

    _authService = AuthService();
    _authService.addListener(_onAuthStateChanged);
    _initialized = true;
  }

  /// Dispose the auth provider
  @override
  void dispose() {
    if (_initialized) {
      _authService.removeListener(_onAuthStateChanged);
      _authService.dispose();
    }
    super.dispose();
  }

  void _onAuthStateChanged() {
    notifyListeners();
  }

  // Getters that delegate to AuthService
  AuthState get state => _authService.state;
  String? get accessToken => _authService.accessToken;
  String? get refreshToken => _authService.refreshToken;
  DateTime? get expiresAt => _authService.expiresAt;
  String? get userId => _authService.userId;
  String? get errorMessage => _authService.errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;
  // Expose saved AppUser for consumers after login
  AppUser? get appUser => _authService.appUser;

  /// Login with Spotify
  Future<void> login() async {
    if (!_initialized) await initialize();
    await _authService.login();
  }

  /// Logout from Spotify
  Future<void> logout() async {
    if (!_initialized) await initialize();
    await _authService.logout();
  }

  /// Clear authentication error
  void clearError() {
    if (_initialized) {
      _authService.clearError();
    }
  }

  /// Test-only: simulate receiving an OAuth callback deep link
  Future<void> testHandleOAuthCallback(Uri uri) async {
    if (!_initialized) await initialize();
    await _authService.testHandleOAuthCallback(uri);
  }
}

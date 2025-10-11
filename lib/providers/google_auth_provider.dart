import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';

/// Google authentication states
enum GoogleAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Google authentication provider
class GoogleAuthProvider extends ChangeNotifier {
  static final GoogleAuthProvider _instance = GoogleAuthProvider._internal();
  factory GoogleAuthProvider() => _instance;
  GoogleAuthProvider._internal();

  late final GoogleAuthService _authService;
  bool _initialized = false;
  
  GoogleAuthState _state = GoogleAuthState.initial;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  /// Initialize the auth provider
  Future<void> initialize() async {
    if (_initialized) return;

    _authService = GoogleAuthService();
    
    // Check if user is already authenticated
    final isAuth = await _authService.isSignedIn();
    if (isAuth) {
      _user = await _authService.getCurrentUser();
      _state = GoogleAuthState.authenticated;
    } else {
      _state = GoogleAuthState.unauthenticated;
    }
    
    _initialized = true;
    notifyListeners();
  }

  /// Dispose the auth provider
  @override
  void dispose() {
    super.dispose();
  }

  // Getters
  GoogleAuthState get state => _state;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == GoogleAuthState.authenticated;
  bool get isLoading => _state == GoogleAuthState.loading;

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _state = GoogleAuthState.loading;
      _errorMessage = null;
      notifyListeners();

      print('🔄 GoogleAuthProvider: Starting Google Sign-In...');
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _user = user;
        _state = GoogleAuthState.authenticated;
        _errorMessage = null;
        print('✅ GoogleAuthProvider: User authenticated successfully');
        print('📊 User Data: $_user');
      } else {
        _state = GoogleAuthState.unauthenticated;
        _errorMessage = 'Sign in cancelled';
        print('❌ GoogleAuthProvider: Sign in cancelled by user');
      }
    } catch (e) {
      _state = GoogleAuthState.error;
      _errorMessage = e.toString();
      print('💥 GoogleAuthProvider: Error during sign-in: $e');
    }
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      print('🔄 GoogleAuthProvider: Starting sign-out...');
      await _authService.signOut();
      _user = null;
      _state = GoogleAuthState.unauthenticated;
      _errorMessage = null;
      print('✅ GoogleAuthProvider: User signed out successfully');
    } catch (e) {
      _state = GoogleAuthState.error;
      _errorMessage = e.toString();
      print('💥 GoogleAuthProvider: Error during sign-out: $e');
    }
    notifyListeners();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _user = null;
      _state = GoogleAuthState.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _state = GoogleAuthState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == GoogleAuthState.error) {
      _state = GoogleAuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _authService.getUserId();
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _authService.getUserEmail();
  }

  /// Get user name
  Future<String?> getUserName() async {
    return await _authService.getUserName();
  }

  /// Get user photo
  Future<String?> getUserPhoto() async {
    return await _authService.getUserPhoto();
  }
}

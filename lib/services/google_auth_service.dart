import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Google Sign-In service for authentication
class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhotoKey = 'user_photo';
  static const String _isAuthenticatedKey = 'is_authenticated';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    final isAuth = await _storage.read(key: _isAuthenticatedKey);
    return isAuth == 'true';
  }

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Store user data directly from Google Sign-In
      await _storage.write(key: _userIdKey, value: googleUser.id);
      await _storage.write(key: _userEmailKey, value: googleUser.email);
      await _storage.write(key: _userNameKey, value: googleUser.displayName ?? '');
      await _storage.write(key: _userPhotoKey, value: googleUser.photoUrl ?? '');
      await _storage.write(key: _isAuthenticatedKey, value: 'true');

      // Log user details
      print('🎉 Google Sign-In Successful!');
      print('👤 User ID: ${googleUser.id}');
      print('📧 Email: ${googleUser.email}');
      print('👨‍💼 Display Name: ${googleUser.displayName}');
      print('🖼️ Photo URL: ${googleUser.photoUrl}');
      print('✅ Authentication Status: Authenticated');

      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoURL': googleUser.photoUrl,
        'isEmailVerified': true,
      };
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final isAuth = await isSignedIn();
      if (!isAuth) return null;

      final userId = await _storage.read(key: _userIdKey);
      final userEmail = await _storage.read(key: _userEmailKey);
      final userName = await _storage.read(key: _userNameKey);
      final userPhoto = await _storage.read(key: _userPhotoKey);

      if (userId == null) return null;

      return {
        'id': userId,
        'email': userEmail ?? '',
        'displayName': userName ?? '',
        'photoURL': userPhoto ?? '',
        'isEmailVerified': true,
      };
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear stored data
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _userNameKey);
      await _storage.delete(key: _userPhotoKey);
      await _storage.delete(key: _isAuthenticatedKey);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear stored data
      await _storage.deleteAll();
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Get user name
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// Get user photo URL
  Future<String?> getUserPhoto() async {
    return await _storage.read(key: _userPhotoKey);
  }
}

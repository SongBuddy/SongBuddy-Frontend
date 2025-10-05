import 'package:dio/dio.dart';

/// Professional API error handling utility
/// Converts raw API errors into user-friendly messages
/// Smart conflict resolution with network status indicators
class ApiErrorHandler {
  /// Convert any error into a user-friendly message
  /// Returns null for network errors to avoid conflicts with network status indicators
  static String? getUserFriendlyMessage(dynamic error) {
    print('🔍 ApiErrorHandler: Processing error: $error');
    
    if (error == null) return 'An unexpected error occurred. Please try again.';

    // Network connectivity errors - return null to avoid conflicts with network status
    if (_isNetworkError(error)) {
      print('🔍 ApiErrorHandler: Detected network error');
      // Temporarily show network errors for debugging
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (_isTimeoutError(error)) {
      return 'Request timed out. Please try again.';
    }

    // Server errors
    if (_isServerError(error)) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Authentication errors
    if (_isAuthError(error)) {
      return 'Authentication failed. Please log in again.';
    }

    // Permission errors
    if (_isPermissionError(error)) {
      return 'You don\'t have permission to perform this action.';
    }

    // Spotify-specific errors
    if (_isSpotifyError(error)) {
      return 'Spotify service is unavailable. Please try again later.';
    }

    // Generic API errors
    if (_isApiError(error)) {
      return 'Service temporarily unavailable. Please try again.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is network-related
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('connection refused') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('no internet connection') ||
           errorString.contains('connection timed out') ||
           errorString.contains('failed to connect') ||
           errorString.contains('connection reset') ||
           (error is DioException && error.type == DioExceptionType.connectionError);
  }

  /// Check if error is timeout-related
  static bool _isTimeoutError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('deadline exceeded') ||
           (error is DioException && error.type == DioExceptionType.receiveTimeout) ||
           (error is DioException && error.type == DioExceptionType.connectionTimeout);
  }

  /// Check if error is server-related
  static bool _isServerError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('500') ||
           errorString.contains('internal server error') ||
           errorString.contains('502') ||
           errorString.contains('bad gateway') ||
           errorString.contains('503') ||
           errorString.contains('service unavailable') ||
           errorString.contains('504') ||
           errorString.contains('gateway timeout') ||
           (error is DioException && 
            error.response?.statusCode != null && 
            error.response!.statusCode! >= 500);
  }

  /// Check if error is authentication-related
  static bool _isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
           errorString.contains('unauthorized') ||
           errorString.contains('invalid token') ||
           errorString.contains('token expired') ||
           errorString.contains('authentication failed') ||
           (error is DioException && error.response?.statusCode == 401);
  }

  /// Check if error is permission-related
  static bool _isPermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('403') ||
           errorString.contains('forbidden') ||
           errorString.contains('access denied') ||
           errorString.contains('permission denied') ||
           (error is DioException && error.response?.statusCode == 403);
  }

  /// Check if error is Spotify-related
  static bool _isSpotifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('spotify') ||
           errorString.contains('spotify app') ||
           errorString.contains('spotify service') ||
           errorString.contains('cannot open spotify') ||
           errorString.contains('spotify unavailable');
  }

  /// Check if error is general API-related
  static bool _isApiError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('api') ||
           errorString.contains('endpoint') ||
           errorString.contains('404') ||
           errorString.contains('not found') ||
           errorString.contains('bad request') ||
           (error is DioException && error.response?.statusCode != null);
  }

  /// Get specific error message for different operations
  /// Returns null for network errors to avoid conflicts with network status indicators
  static String? getOperationErrorMessage(String operation, dynamic error) {
    final baseMessage = getUserFriendlyMessage(error);
    if (baseMessage == null) return null; // Don't show snackbar for network errors
    
    switch (operation.toLowerCase()) {
      case 'create_post':
        return 'Failed to create post. $baseMessage';
      case 'update_post':
        return 'Failed to update post. $baseMessage';
      case 'delete_post':
        return 'Failed to delete post. $baseMessage';
      case 'toggle_like':
        return 'Failed to update like. $baseMessage';
      case 'follow_user':
        return 'Failed to follow user. $baseMessage';
      case 'unfollow_user':
        return 'Failed to unfollow user. $baseMessage';
      case 'load_posts':
        return 'Failed to load posts. $baseMessage';
      case 'load_profile':
        return 'Failed to load profile. $baseMessage';
      case 'load_followers':
        return 'Failed to load followers. $baseMessage';
      case 'load_following':
        return 'Failed to load following. $baseMessage';
      case 'search_posts':
        return 'Failed to search posts. $baseMessage';
      case 'open_spotify':
        return 'Cannot open Spotify. Please install Spotify app or try again.';
      case 'save_user':
        return 'Failed to save user data. $baseMessage';
      case 'delete_user':
        return 'Failed to delete user. $baseMessage';
      default:
        return baseMessage;
    }
  }

  /// Get error severity for UI styling
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (_isNetworkError(error) || _isTimeoutError(error)) {
      return ErrorSeverity.warning; // Orange/yellow
    }
    
    if (_isServerError(error) || _isAuthError(error)) {
      return ErrorSeverity.error; // Red
    }
    
    return ErrorSeverity.info; // Blue/default
  }
}

/// Error severity levels for UI styling
enum ErrorSeverity {
  info,    // Blue/default - informational
  warning, // Orange/yellow - network/timeout issues
  error,   // Red - server/auth issues
}

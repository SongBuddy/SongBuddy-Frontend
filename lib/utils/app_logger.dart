import 'package:flutter/foundation.dart';

/// Clean logging utility for SongBuddy
///
/// Benefits:
/// - Zero performance impact in release builds
/// - Consistent log formatting
/// - Easy to disable/enable logs
/// - Colored output for better readability
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in successfully');
/// AppLogger.error('Failed to load posts', error: e);
/// AppLogger.debug('Current state: $state');
/// ```
class AppLogger {
  // Only show logs in debug mode
  static const bool _enableLogs = kDebugMode;

  // Log level control
  static const bool _showDebugLogs = true;
  static const bool _showInfoLogs = true;
  static const bool _showWarningLogs = true;
  static const bool _showErrorLogs = true;

  /// Log general information
  /// Example: AppLogger.info('User logged in')
  static void info(String message, {String? tag}) {
    if (!_enableLogs || !_showInfoLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('ℹ️ $prefix $message');
  }

  /// Log debug information (detailed technical info)
  /// Example: AppLogger.debug('Token: ${token.substring(0, 10)}...')
  static void debug(String message, {String? tag}) {
    if (!_enableLogs || !_showDebugLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('🔍 $prefix $message');
  }

  /// Log warnings
  /// Example: AppLogger.warning('Cache is full, clearing old entries')
  static void warning(String message, {String? tag}) {
    if (!_enableLogs || !_showWarningLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('⚠️ $prefix $message');
  }

  /// Log errors
  /// Example: AppLogger.error('Failed to load posts', error: e, stackTrace: st)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!_enableLogs || !_showErrorLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('❌ $prefix $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   Stack trace:\n$stackTrace');
    }
  }

  /// Log success messages
  /// Example: AppLogger.success('Post created successfully')
  static void success(String message, {String? tag}) {
    if (!_enableLogs || !_showInfoLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('✅ $prefix $message');
  }

  /// Log network requests
  /// Example: AppLogger.network('GET', '/api/posts')
  static void network(String method, String endpoint, {int? statusCode}) {
    if (!_enableLogs || !_showDebugLogs) return;
    final status = statusCode != null ? ' -> $statusCode' : '';
    debugPrint('🌐 [Network] $method $endpoint$status');
  }

  /// Log navigation events
  /// Example: AppLogger.navigation('Navigated to HomeScreen')
  static void navigation(String message) {
    if (!_enableLogs || !_showDebugLogs) return;
    debugPrint('🧭 [Navigation] $message');
  }

  /// Log authentication events
  /// Example: AppLogger.auth('User logged in')
  static void auth(String message) {
    if (!_enableLogs || !_showInfoLogs) return;
    debugPrint('🔐 [Auth] $message');
  }

  /// Log sync/background events
  /// Example: AppLogger.sync('Background sync started')
  static void sync(String message) {
    if (!_enableLogs || !_showDebugLogs) return;
    debugPrint('🔄 [Sync] $message');
  }
}

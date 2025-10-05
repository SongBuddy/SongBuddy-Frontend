import 'package:flutter/material.dart';
import 'package:songbuddy/services/professional_sync_service.dart';

/// Simple lifecycle manager - like professional apps
/// Minimal overhead, maximum efficiency
class SimpleLifecycleManager with WidgetsBindingObserver {
  static SimpleLifecycleManager? _instance;
  static SimpleLifecycleManager get instance {
    _instance ??= SimpleLifecycleManager._internal();
    return _instance!;
  }

  SimpleLifecycleManager._internal();

  final ProfessionalSyncService _syncService = ProfessionalSyncService.instance;
  bool _isInitialized = false;

  /// Initialize the lifecycle manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔄 SimpleLifecycleManager: Initializing');
    WidgetsBinding.instance.addObserver(this);
    await _syncService.initialize();
    _isInitialized = true;
    debugPrint('✅ SimpleLifecycleManager: Initialized');
  }

  /// Start sync service
  Future<void> start() async {
    if (!_isInitialized) await initialize();
    debugPrint('🔄 SimpleLifecycleManager: Starting sync');
    await _syncService.start();
  }

  /// Stop sync service
  Future<void> stop() async {
    debugPrint('🔄 SimpleLifecycleManager: Stopping sync');
    await _syncService.stop();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncService.handleAppStateChange(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _syncService.handleAppStateChange(false);
        break;
    }
  }

  /// Force sync
  Future<void> forceSync() async {
    await _syncService.forceSync();
  }

  /// Get current status
  String get status => _syncService.status;

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncService.dispose();
    _isInitialized = false;
  }
}


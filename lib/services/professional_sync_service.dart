import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:songbuddy/services/spotify_service.dart';
import 'package:songbuddy/services/backend_service.dart';

/// Professional sync service - like Spotify, Instagram, Uber
/// Single service that adapts based on app state
/// Lightweight, efficient, and crash-free
class ProfessionalSyncService {
  static ProfessionalSyncService? _instance;
  static ProfessionalSyncService get instance {
    _instance ??= ProfessionalSyncService._internal();
    return _instance!;
  }

  ProfessionalSyncService._internal();

  // Services
  final SpotifyService _spotifyService = SpotifyService();
  final BackendService _backendService = BackendService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // State management
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isActive = false;
  bool _isAppInForeground = true;
  Map<String, dynamic>? _lastCurrentlyPlaying;
  
  // Sync intervals (like professional apps)
  static const Duration _foregroundInterval = Duration(seconds: 15); // Like Spotify
  static const Duration _backgroundInterval = Duration(seconds: 10);  // Battery efficient

  /// Initialize the service (called once at app start)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🎵 ProfessionalSyncService: Initializing');
    _isInitialized = true;
    debugPrint('✅ ProfessionalSyncService: Initialized');
  }

  /// Start sync service (called when user is authenticated)
  Future<void> start() async {
    if (!_isInitialized) await initialize();
    if (_isActive) return;
    
    debugPrint('🎵 ProfessionalSyncService: Starting');
    _isActive = true;
    
    // Start with appropriate interval based on app state
    _startSyncTimer();
    debugPrint('✅ ProfessionalSyncService: Started');
  }

  /// Stop sync service (called when user logs out)
  Future<void> stop() async {
    if (!_isActive) return;
    
    debugPrint('🎵 ProfessionalSyncService: Stopping');
    _stopSyncTimer();
    _isActive = false;
    debugPrint('✅ ProfessionalSyncService: Stopped');
  }

  /// Handle app lifecycle changes (foreground/background)
  void handleAppStateChange(bool isForeground) {
    if (!_isActive) return;
    
    if (_isAppInForeground != isForeground) {
      _isAppInForeground = isForeground;
      debugPrint('🎵 ProfessionalSyncService: App ${isForeground ? 'foreground' : 'background'}');
      
      // Restart timer with appropriate interval
      _startSyncTimer();
    }
  }

  /// Force immediate sync (for user actions)
  Future<void> forceSync() async {
    if (!_isActive) return;
    debugPrint('🎵 ProfessionalSyncService: Force sync requested');
    await _performSync();
  }

  /// Start sync timer with appropriate interval
  void _startSyncTimer() {
    _stopSyncTimer();
    
    final interval = _isAppInForeground ? _foregroundInterval : _backgroundInterval;
    debugPrint('🎵 ProfessionalSyncService: Starting timer (${interval.inSeconds}s intervals)');
    
    _syncTimer = Timer.periodic(interval, (timer) {
      _performSync();
    });
  }

  /// Stop sync timer
  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Perform sync operation (the core logic)
  Future<void> _performSync() async {
    try {
      // Get credentials
      final accessToken = await _secureStorage.read(key: 'spotify_access_token');
      final userId = await _secureStorage.read(key: 'spotify_user_id');

      if (accessToken == null || userId == null || 
          accessToken.isEmpty || userId.isEmpty) {
        return; // Skip silently - no need to spam logs
      }

      // Get currently playing from Spotify
      final currentlyPlaying = await _spotifyService.getCurrentlyPlaying(accessToken);

      // Check if song has changed
      if (_hasSongChanged(_lastCurrentlyPlaying, currentlyPlaying)) {
        debugPrint('🎵 ProfessionalSyncService: Song changed - syncing');
        
        // Sync to backend
        final success = await _backendService.updateCurrentlyPlaying(
          userId,
          currentlyPlaying,
        );

        if (success) {
          _lastCurrentlyPlaying = currentlyPlaying;
          debugPrint('✅ ProfessionalSyncService: Synced successfully');
        }
      }
    } catch (e) {
      // Silent error handling - don't spam logs with network errors
      debugPrint('🎵 ProfessionalSyncService: Sync error (handled): ${e.runtimeType}');
    }
  }

  /// Check if song has changed
  bool _hasSongChanged(Map<String, dynamic>? old, Map<String, dynamic>? current) {
    if (old == null && current == null) return false;
    if (old == null || current == null) return true;
    
    final oldTrackId = old['item']?['id'] ?? old['id'];
    final newTrackId = current['item']?['id'] ?? current['id'];
    
    return oldTrackId != newTrackId;
  }

  /// Get current status
  String get status {
    if (!_isActive) return 'Stopped';
    return 'Active (${_isAppInForeground ? 'Foreground' : 'Background'})';
  }

  /// Check if service is active
  bool get isActive => _isActive;

  /// Dispose resources
  void dispose() {
    _stopSyncTimer();
    _isInitialized = false;
    _isActive = false;
  }
}


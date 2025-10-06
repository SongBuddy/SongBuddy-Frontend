import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Global internet connectivity service based on connectivity_plus
class InternetConnectionService {
  static InternetConnectionService? _instance;
  static InternetConnectionService get instance {
    _instance ??= InternetConnectionService._internal();
    return _instance!;
  }

  InternetConnectionService._internal();

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityTimer;
  bool _isConnected = true;
  bool _isInitialized = false;

  /// Stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initialize the connection monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check initial connection status
      await _checkInternetConnection();
      
      // Start monitoring connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
      );
      
      _isInitialized = true;
      print('✅ InternetConnectionService: Initialized');
    } catch (e) {
      print('❌ InternetConnectionService: Failed to initialize: $e');
      // Default to connected if we can't determine status
      _isConnected = true;
      _connectionController.add(_isConnected);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    print('🔧 InternetConnectionService: Connectivity changed: $results');
    
    // Cancel any existing timer
    _connectivityTimer?.cancel();
    
    // Check if we have any connection
    final hasConnection = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    
    if (!hasConnection) {
      // No connection at all
      _updateConnectionStatus(false);
    } else {
      // We have a connection, but need to verify internet access
      // Add a small delay to avoid rapid changes
      _connectivityTimer = Timer(const Duration(seconds: 1), () {
        _checkInternetConnection();
      });
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      print('🔧 InternetConnectionService: Checking internet connection...');
      
      // Try to connect to a reliable server
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionStatus(isConnected);
      
      print('🔧 InternetConnectionService: Internet check result: $isConnected');
    } catch (e) {
      print('🔧 InternetConnectionService: Internet check failed: $e');
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      print('🌐 InternetConnectionService: Connection status changed from $_isConnected to $isConnected');
      _isConnected = isConnected;
      _connectionController.add(_isConnected);
    }
  }

  /// Check connection status manually
  Future<bool> checkConnection() async {
    await _checkInternetConnection();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();
    _connectionController.close();
    _isInitialized = false;
    print('🔄 InternetConnectionService: Disposed');
  }
}
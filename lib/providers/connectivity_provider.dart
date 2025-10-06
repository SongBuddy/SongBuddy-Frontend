import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity result provider
final connectivityResultProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Internet connectivity provider
final internetConnectivityProvider = StreamProvider<bool>((ref) {
  final connectivityStream = ref.watch(connectivityResultProvider.stream);
  
  return connectivityStream.asyncMap((connectivityResults) async {
    // Check if we have any connection
    final hasConnection = connectivityResults.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    
    if (!hasConnection) {
      return false;
    }
    
    // We have a connection, verify internet access
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  });
});

/// Current internet status provider
final internetStatusProvider = Provider<bool>((ref) {
  final internetStatus = ref.watch(internetConnectivityProvider);
  return internetStatus.when(
    data: (isConnected) => isConnected,
    loading: () => true, // Default to connected during loading
    error: (_, __) => false, // Default to disconnected on error
  );
});

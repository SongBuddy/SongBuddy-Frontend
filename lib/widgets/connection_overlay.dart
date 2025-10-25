import 'dart:async';
import 'package:flutter/material.dart';
import 'package:songbuddy/services/internet_connection_service.dart';
import 'package:songbuddy/widgets/no_internet_popup.dart';
import 'package:songbuddy/widgets/offline_snackbar.dart';

/// Overlay widget that monitors internet connection and shows/hides UI elements
class ConnectionOverlay extends StatefulWidget {
  final Widget child;

  const ConnectionOverlay({
    super.key,
    required this.child,
  });

  @override
  State<ConnectionOverlay> createState() => _ConnectionOverlayState();
}

class _ConnectionOverlayState extends State<ConnectionOverlay> {
  StreamSubscription<bool>? _connectionSubscription;
  bool _showPopup = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectionMonitoring();
  }

  void _initializeConnectionMonitoring() {
    final connectionService = InternetConnectionService.instance;

    // Listen to connection changes
    _connectionSubscription = connectionService.connectionStream.listen(
      (isConnected) {
        if (mounted) {
          _handleConnectionChange(isConnected);
        }
      },
    );
  }

  void _handleConnectionChange(bool isConnected) {
    if (!isConnected) {
      // Show popup and snackbar when disconnected
      if (!_showPopup) {
        _showPopup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NoInternetPopup.show(context);
            OfflineSnackbar.show(context);
          }
        });
      }
    } else {
      // Hide popup and show online snackbar when connected
      if (_showPopup) {
        _showPopup = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NoInternetPopup.hide(context);
            OfflineSnackbar.showOnline(context);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songbuddy/providers/connectivity_provider.dart';
import 'package:songbuddy/widgets/no_internet_popup.dart';
import 'package:songbuddy/widgets/offline_snackbar.dart';

/// Riverpod-based connection overlay that monitors internet connectivity
class RiverpodConnectionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const RiverpodConnectionOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RiverpodConnectionOverlay> createState() =>
      _RiverpodConnectionOverlayState();
}

class _RiverpodConnectionOverlayState
    extends ConsumerState<RiverpodConnectionOverlay> {
  bool _showPopup = false;
  bool _lastConnectionState = true;
  StreamSubscription<bool>? _connectionSubscription;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeConnectionMonitoring();
  }

  void _initializeConnectionMonitoring() {
    // Listen to connection changes directly from the provider
    _connectionSubscription =
        ref.read(internetConnectivityProvider.stream).listen(
      (isConnected) {
        if (mounted && _lastConnectionState != isConnected) {
          _lastConnectionState = isConnected;
          _handleConnectionChange(isConnected);
        }
      },
      onError: (error) {
        if (mounted && _lastConnectionState != false) {
          _lastConnectionState = false;
          _handleConnectionChange(false);
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _handleConnectionChange(bool isConnected) {
    if (!mounted) return;

    if (!isConnected) {
      // Show popup and snackbar when disconnected
      if (!_showPopup) {
        _showPopup = true;
        _showOfflineUI();
      }
    } else {
      // Hide popup and show online snackbar when connected
      if (_showPopup) {
        _showPopup = false;
        _showOnlineUI();
      }
    }
  }

  void _showOfflineUI() {
    if (!mounted) return;

    // Show snackbar
    OfflineSnackbar.show(context);

    // Show popup using overlay (no navigation issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlayPopup();
      }
    });
  }

  void _showOverlayPopup() {
    if (!mounted || _overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap:
                  () {}, // Prevent tap from closing when tapping popup itself
              child: const NoInternetPopup(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOnlineUI() {
    if (!mounted) return;

    // Remove overlay popup safely
    _removeOverlay();

    // Show online snackbar
    OfflineSnackbar.showOnline(context);
  }
}

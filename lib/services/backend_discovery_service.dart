import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BackendDiscoveryService {
  // Common IP addresses to try
  static const List<String> commonIPs = [
    '127.0.0.1', // Localhost
    '10.0.2.2', // Android Emulator
    'localhost', // Fallback
  ];

  // Common ports to try
  static const List<int> commonPorts = [3000, 3001, 8080, 8000];

  // Cache for discovered backend
  static String? _discoveredBackendUrl;
  static DateTime? _lastDiscovery;
  static const Duration cacheTimeout = Duration(minutes: 5);

  /// Discover the backend URL automatically
  static Future<String?> discoverBackend() async {
    // Check cache first
    if (_discoveredBackendUrl != null &&
        _lastDiscovery != null &&
        DateTime.now().difference(_lastDiscovery!) < cacheTimeout) {
      return _discoveredBackendUrl;
    }

    print('🔍 Discovering backend...');

    // Try common IPs and ports
    for (String ip in commonIPs) {
      for (int port in commonPorts) {
        String url = 'http://$ip:$port';
        if (await _testBackend(url)) {
          _discoveredBackendUrl = url;
          _lastDiscovery = DateTime.now();
          print('✅ Backend discovered at: $url');
          return url;
        }
      }
    }

    // Try to get local network IPs
    await _tryLocalNetworkIPs();

    print('❌ Backend not found automatically');
    return null;
  }

  /// Test if a backend URL is reachable
  static Future<bool> _testBackend(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      // Connection failed, try next URL
    }
    return false;
  }

  /// Try to discover local network IPs
  static Future<void> _tryLocalNetworkIPs() async {
    try {
      // Get local IP addresses
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith('169.254.')) {
            // Skip auto-assigned IPs

            String ip = addr.address;
            for (int port in commonPorts) {
              String url = 'http://$ip:$port';
              if (await _testBackend(url)) {
                _discoveredBackendUrl = url;
                _lastDiscovery = DateTime.now();
                print('✅ Backend discovered at: $url');
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error discovering local network IPs: $e');
    }
  }

  /// Get the discovered backend URL
  static String? getDiscoveredBackend() {
    return _discoveredBackendUrl;
  }

  /// Clear the discovery cache
  static void clearCache() {
    _discoveredBackendUrl = null;
    _lastDiscovery = null;
  }

  /// Manual backend URL configuration
  static void setBackendUrl(String url) {
    _discoveredBackendUrl = url;
    _lastDiscovery = DateTime.now();
  }
}

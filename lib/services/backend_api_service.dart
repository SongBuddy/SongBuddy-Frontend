import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_discovery_service.dart';

class BackendApiService {
  // Dynamic backend URL discovery
  static String? _baseUrl;
  
  // Fallback URLs if discovery fails
  static const List<String> fallbackUrls = [
    'http://172.20.135.128:3000',  // Your Mac's IP
    'http://127.0.0.1:3000',       // Localhost
    'http://10.0.2.2:3000',        // Android Emulator
  ];
  
  /// Get the backend base URL (with automatic discovery)
  static Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    
    // Try to discover backend automatically
    String? discoveredUrl = await BackendDiscoveryService.discoverBackend();
    if (discoveredUrl != null) {
      _baseUrl = discoveredUrl;
      return _baseUrl!;
    }
    
    // Fallback to hardcoded URLs
    for (String url in fallbackUrls) {
      if (await _testUrl(url)) {
        _baseUrl = url;
        return _baseUrl!;
      }
    }
    
    // Last resort
    _baseUrl = fallbackUrls.first;
    return _baseUrl!;
  }
  
  /// Test if a URL is reachable
  static Future<bool> _testUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Test connection to backend
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/api/test'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Backend connection failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
  
  // Test POST request to backend
  static Future<Map<String, dynamic>> testPostConnection(String message) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/api/test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Backend POST failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to POST to backend: $e');
    }
  }
  
  // Get backend health status
  static Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get health status: $e');
    }
  }
  
  /// Get the current backend URL being used
  static Future<String> getCurrentBackendUrl() async {
    return await baseUrl;
  }
  
  /// Clear the backend URL cache (force rediscovery)
  static void clearBackendCache() {
    _baseUrl = null;
    BackendDiscoveryService.clearCache();
  }
}

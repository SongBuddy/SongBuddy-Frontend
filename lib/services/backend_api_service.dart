import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApiService {
  // Use your Mac's IP address instead of localhost
  // For iOS Simulator: use 127.0.0.1
  // For Android Emulator: use 10.0.2.2
  // For physical device: use your Mac's IP address
  static const String baseUrl = 'http://172.20.135.128:3000';
  
  // Test connection to backend
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/test'),
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
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
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
}

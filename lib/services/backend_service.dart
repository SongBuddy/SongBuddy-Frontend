import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:songbuddy/constants/UrlConstant.dart';
import 'package:songbuddy/models/AppUser.dart';


class BackendService {
 

  Future<AppUser?> saveUser(AppUser user) async {
    final response = await http.post(
      Uri.parse("${Url.baseUrl}/users/save"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser(
        id: data['id'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'] ?? '',
        country: data['country'] ?? 'US',
        currentlyPlaying: data['currentlyPlaying'],
        topArtists: data['topArtists'] != null 
            ? List<Map<String, dynamic>>.from(data['topArtists'])
            : [],
        topTracks: data['topTracks'] != null 
            ? List<Map<String, dynamic>>.from(data['topTracks'])
            : [],
        recentlyPlayed: data['recentlyPlayed'] != null 
            ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
            : [],
      );
    } else {
      throw Exception("Failed to save user: ${response.body}");
    }
  }

  /// Update user fields (all fields except id are updatable)
  Future<AppUser?> updateUser(String userId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse("${Url.baseUrl}/users/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser(
        id: data['id'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'] ?? '',
        country: data['country'] ?? 'US',
        currentlyPlaying: data['currentlyPlaying'],
        topArtists: data['topArtists'] != null 
            ? List<Map<String, dynamic>>.from(data['topArtists'])
            : [],
        topTracks: data['topTracks'] != null 
            ? List<Map<String, dynamic>>.from(data['topTracks'])
            : [],
        recentlyPlayed: data['recentlyPlayed'] != null 
            ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
            : [],
      );
    } else {
      throw Exception("Failed to update user: ${response.body}");
    }
  }

  /// Delete user from backend
  Future<bool> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse("${Url.baseUrl}/users/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception("Failed to delete user: ${response.body}");
    }
  }

  /// Get user information from backend
  Future<AppUser?> getUser(String userId) async {
    final response = await http.get(
      Uri.parse("${Url.baseUrl}/users/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser(
        id: data['id'] ?? '',
        displayName: data['displayName'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'] ?? '',
        country: data['country'] ?? 'US',
        currentlyPlaying: data['currentlyPlaying'],
        topArtists: data['topArtists'] != null 
            ? List<Map<String, dynamic>>.from(data['topArtists'])
            : [],
        topTracks: data['topTracks'] != null 
            ? List<Map<String, dynamic>>.from(data['topTracks'])
            : [],
        recentlyPlayed: data['recentlyPlayed'] != null 
            ? List<Map<String, dynamic>>.from(data['recentlyPlayed'])
            : [],
      );
    } else {
      throw Exception("Failed to get user: ${response.body}");
    }
  }
}

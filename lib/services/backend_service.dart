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
      );
    } else {
      throw Exception("Failed to save user: ${response.body}");
    }
  }
}

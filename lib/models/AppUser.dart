class AppUser {
  final String id;
  final String country;
  final String displayName;
  final String email;
  final String profilePicture;

  AppUser({
    required this.id,
    required this.country,
    required this.displayName,
    required this.email,
    required this.profilePicture,
  });

  factory AppUser.fromSpotify(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      country: json['country'],
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['url']
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "displayName": displayName,
      "email": email,
      "profilePicture": profilePicture,
    };
  }
}
class AppUser {
  final String id;
  final String country;
  final String displayName;
  final String email;
  final String profilePicture;
  final Map<String, dynamic>? currentlyPlaying;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topTracks;
  final List<Map<String, dynamic>> recentlyPlayed;

  AppUser({
    required this.id,
    required this.country,
    required this.displayName,
    required this.email,
    required this.profilePicture,
    this.currentlyPlaying,
    this.topArtists = const [],
    this.topTracks = const [],
    this.recentlyPlayed = const [],
  });

  factory AppUser.fromSpotify(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      country: json['country'] ?? 'US',
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['url'] ?? ''
          : '',
      currentlyPlaying: json['currentlyPlaying'],
      topArtists: json['topArtists'] != null 
          ? List<Map<String, dynamic>>.from(json['topArtists'])
          : [],
      topTracks: json['topTracks'] != null 
          ? List<Map<String, dynamic>>.from(json['topTracks'])
          : [],
      recentlyPlayed: json['recentlyPlayed'] != null 
          ? List<Map<String, dynamic>>.from(json['recentlyPlayed'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "displayName": displayName,
      "email": email,
      "profilePicture": profilePicture,
      "country": country,
      "currentlyPlaying": currentlyPlaying,
      "topArtists": topArtists,
      "topTracks": topTracks,
      "recentlyPlayed": recentlyPlayed,
    };
  }
}
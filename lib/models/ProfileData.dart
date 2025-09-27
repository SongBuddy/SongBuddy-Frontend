import 'Post.dart';

class ProfileData {
  final User user;
  final List<Post> posts;
  final Pagination pagination;
  // Music sections data
  final Map<String, dynamic>? currentlyPlaying;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topTracks;
  final List<Map<String, dynamic>> recentlyPlayed;

  const ProfileData({
    required this.user,
    required this.posts,
    required this.pagination,
    this.currentlyPlaying,
    this.topArtists = const [],
    this.topTracks = const [],
    this.recentlyPlayed = const [],
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // Extract music data from the user object
    final userJson = json['user'] as Map<String, dynamic>;
    
    return ProfileData(
      user: User.fromJson(userJson),
      posts: (json['posts'] as List<dynamic>)
          .map((post) => Post.fromJson(post))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
      // Music data is inside the user object
      currentlyPlaying: userJson['currentlyPlaying'] as Map<String, dynamic>?,
      topArtists: userJson['topArtists'] != null 
          ? List<Map<String, dynamic>>.from(userJson['topArtists'])
          : const [],
      topTracks: userJson['topTracks'] != null 
          ? List<Map<String, dynamic>>.from(userJson['topTracks'])
          : const [],
      recentlyPlayed: userJson['recentlyPlayed'] != null 
          ? List<Map<String, dynamic>>.from(userJson['recentlyPlayed'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'posts': posts.map((post) => post.toJson()).toList(),
      'pagination': pagination.toJson(),
      'currentlyPlaying': currentlyPlaying,
      'topArtists': topArtists,
      'topTracks': topTracks,
      'recentlyPlayed': recentlyPlayed,
    };
  }
}

class User {
  final String id;
  final String displayName;
  final String username;
  final String profilePicture;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing; // New field for follow status

  const User({
    required this.id,
    required this.displayName,
    required this.username,
    required this.profilePicture,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.isFollowing = false, // Default to false
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String,
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
      postsCount: json['postsCount'] as int,
      isFollowing: json['isFollowing'] as bool? ?? false, // Handle missing field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'profilePicture': profilePicture,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isFollowing': isFollowing,
    };
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
    };
  }
}

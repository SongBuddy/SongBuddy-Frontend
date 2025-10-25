class Post {
  final String id;
  final String userId;
  final String username;
  final String userProfilePicture;
  final String songName;
  final String artistName;
  final String songImage;
  final String? description;
  final int likeCount;
  final DateTime createdAt;
  final String timeline; // e.g., "8h", "2d", "1w"
  final bool isLikedByCurrentUser;

  const Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePicture,
    required this.songName,
    required this.artistName,
    required this.songImage,
    this.description,
    required this.likeCount,
    required this.createdAt,
    required this.timeline,
    this.isLikedByCurrentUser = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String? ??
          '', // Use empty string as fallback for update operations
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown User',
      userProfilePicture: json['userProfilePicture'] as String? ?? '',
      songName: json['songName'] as String? ?? 'Unknown Song',
      artistName: json['artistName'] as String? ?? 'Unknown Artist',
      songImage: json['songImage'] as String? ?? '',
      description: json['description'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      timeline: json['timeline'] as String? ?? 'now',
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfilePicture': userProfilePicture,
      'songName': songName,
      'artistName': artistName,
      'songImage': songImage,
      'description': description,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'timeline': timeline,
      'isLikedByCurrentUser': isLikedByCurrentUser,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfilePicture,
    String? songName,
    String? artistName,
    String? songImage,
    String? description,
    int? likeCount,
    DateTime? createdAt,
    String? timeline,
    bool? isLikedByCurrentUser,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      songImage: songImage ?? this.songImage,
      description: description ?? this.description,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      timeline: timeline ?? this.timeline,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}

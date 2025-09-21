import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/screens/notification_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final List<Map<String, dynamic>> _allPosts = [
    {
      "username": "Amin",
      "avatarUrl": "https://i.pravatar.cc/150?img=1",
      "trackTitle": "Blinding Lights",
      "artist": "The Weeknd",
      "coverUrl":
          "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
      "description": "This track always gives me a boost of energy 🚀🔥",
      "likes": 124,
      "time": "2h"
    },
    {
      "username": "Sara",
      "avatarUrl": "https://i.pravatar.cc/150?img=2",
      "trackTitle": "Levitating",
      "artist": "Dua Lipa",
      "coverUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s",
      "description": "",
      "likes": 89,
      "time": "6h"
    },
    {
      "username": "John",
      "avatarUrl": "https://i.pravatar.cc/150?img=3",
      "trackTitle": "As It Was",
      "artist": "Harry Styles",
      "coverUrl":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF0Jqpe95kORYuGnJhSprCr8KG_WtwW8oS9Q&ss",
      "description": "Makes me feel nostalgic ✨",
      "likes": 211,
      "time": "1d"
    },
  ];

  late List<Map<String, dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = List<Map<String, dynamic>>.from(_allPosts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      "SongBuddy",
                      style: AppTextStyles.heading2OnDark.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> NotificationScreen()));
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.onDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(color: Colors.white.withOpacity(0.04), height: 1),
              ),

              // Feed
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _BlurPostCard(
                      username: post['username'] as String,
                      avatarUrl: post['avatarUrl'] as String,
                      trackTitle: post['trackTitle'] as String,
                      artist: post['artist'] as String,
                      coverUrl: post['coverUrl'] as String,
                      description: post['description'] as String,
                      initialLikes: post['likes'] as int,
                      timeAgo: post['time'] as String,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurPostCard extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String trackTitle;
  final String artist;
  final String coverUrl;
  final String description;
  final int initialLikes;
  final String timeAgo;

  const _BlurPostCard({
    required this.username,
    required this.avatarUrl,
    required this.trackTitle,
    required this.artist,
    required this.coverUrl,
    required this.description,
    required this.initialLikes,
    required this.timeAgo,
  });

  @override
  State<_BlurPostCard> createState() => _BlurPostCardState();
}

class _BlurPostCardState extends State<_BlurPostCard> {
  bool isLiked = false;
  late int likes;

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes = isLiked ? likes + 1 : likes - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Background blurred cover art
          Image.network(
            widget.coverUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 165,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 165,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),

          // Foreground content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12 , vertical: 5),
            height: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + username | time
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(widget.avatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      widget.timeAgo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Middle row: cover art + song info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        widget.coverUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.trackTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.artist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.description.isNotEmpty)
                            Text(
                              widget.description,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Bottom row: like + share
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _toggleLike,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white70,
                        size: 18,
                      ),
                    ),
                    Text(
                      "$likes",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

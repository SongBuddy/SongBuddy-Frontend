import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/screens/notification_screen.dart';
import 'package:songbuddy/widgets/music_post_card.dart';

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
                    return MusicPostCard(
                      username: post['username'] as String,
                      avatarUrl: post['avatarUrl'] as String,
                      trackTitle: post['trackTitle'] as String,
                      artist: post['artist'] as String,
                      coverUrl: post['coverUrl'] as String,
                      description: post['description'] as String,
                      initialLikes: post['likes'] as int,
                      timeAgo: post['time'] as String,
                      height: 180,
                      avatarVerticalPadding: 6,
                      onShare: () {
                        final text = """
                              🎵 ${post['trackTitle']} - ${post['artist']}
                              Posted by ${post['username']}

                              ${post['description'].isNotEmpty ? post['description'] : ''}
                              """;
                        Share.share(
                          text,
                          subject: "Check out this song on SongBuddy!",
                        );
                      },
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

// Removed old _BlurPostCard in favor of reusable MusicPostCard

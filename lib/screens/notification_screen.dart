import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:songbuddy/constants/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> notifications = const [
    {
      "type": "follow",
      "actor": "Alice",
      "avatarUrl": "https://i.pravatar.cc/100?img=1",
      "time": "2m"
    },
    {
      "type": "like",
      "actor": "Bob",
      "avatarUrl": "https://i.pravatar.cc/100?img=2",
      "time": "5m",
      "postTitle": "Night Changes",
      "coverUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s"
    },
    {
      "type": "new_post",
      "actor": "Sara",
      "avatarUrl": "https://i.pravatar.cc/100?img=3",
      "time": "15m",
      "postTitle": "Blinding Lights",
      "coverUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s"
    },
  ];

  IconData _getIcon(String type) {
    switch (type) {
      case "follow":
        return Icons.person_add_alt_1;
      case "like":
        return Icons.favorite;
      case "new_post":
        return Icons.music_note;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case "follow":
        return AppColors.primary;
      case "like":
        return AppColors.secondary;
      case "new_post":
        return AppColors.accentGreen;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Notifications",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(notification["avatarUrl"]),
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessage(notification),
                      const SizedBox(height: 4),
                      Text(notification["time"],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),

                // Right-side action (icon or cover)
                if (notification["coverUrl"] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: notification["coverUrl"],
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getIconColor(notification["type"]).withOpacity(0.15),
                    ),
                    child: Icon(_getIcon(notification["type"]),
                        size: 20, color: _getIconColor(notification["type"])),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> notification) {
    final type = notification["type"];
    final actor = notification["actor"];

    switch (type) {
      case "follow":
        return RichText(
          text: TextSpan(children: [
            TextSpan(
                text: actor,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const TextSpan(
                text: " followed you",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        );
      case "like":
        return RichText(
          text: TextSpan(children: [
            TextSpan(
                text: actor,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            TextSpan(
                text: " liked your post • ${notification["postTitle"]}",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        );
      case "new_post":
        return RichText(
          text: TextSpan(children: [
            TextSpan(
                text: actor,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            TextSpan(
                text: " posted: ${notification["postTitle"]}",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        );
      default:
        return const Text("New notification",
            style: TextStyle(color: Colors.white));
    }
  }
}

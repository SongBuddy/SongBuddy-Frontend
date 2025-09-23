import 'dart:ui';
import 'package:flutter/material.dart';

class MusicPostCard extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String trackTitle;
  final String artist;
  final String coverUrl;
  final String timeAgo;
  final String? description;

  final int initialLikes;
  final bool isInitiallyLiked;

  final VoidCallback? onCardTap;
  final VoidCallback? onShare;
  final void Function(bool isLiked, int likes)? onLikeChanged;
  final VoidCallback? onFollowPressed;

  final bool showFollowButton;
  final double height;
  final double borderRadius;
  final double overlayOpacity;
  final double avatarVerticalPadding;

  const MusicPostCard({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.trackTitle,
    required this.artist,
    required this.coverUrl,
    required this.timeAgo,
    this.description,
    this.onCardTap,
    this.onShare,
    this.onLikeChanged,
    this.onFollowPressed,
    this.showFollowButton = false,
    this.height = 165,
    this.borderRadius = 18,
    this.overlayOpacity = 0.35,
    this.initialLikes = 0,
    this.isInitiallyLiked = false,
    this.avatarVerticalPadding = 0,
  });

  @override
  State<MusicPostCard> createState() => _MusicPostCardState();
}

class _MusicPostCardState extends State<MusicPostCard> {
  late bool isLiked;
  late int likes;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isInitiallyLiked;
    likes = widget.initialLikes;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes = (isLiked ? likes + 1 : likes - 1).clamp(0, 999999);
    });
    widget.onLikeChanged?.call(isLiked, likes);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: GestureDetector(
        onTap: widget.onCardTap,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            children: [
              // Blurred background cover
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Image.network(
                    widget.coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Dark overlay to improve contrast
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(widget.overlayOpacity),
                  ),
                ),
              ),

              // Foreground content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: avatar + username | time | optional follow
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: widget.avatarVerticalPadding,
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(widget.avatarUrl),
                          ),
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
                        if (widget.showFollowButton) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: widget.onFollowPressed,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text(
                              "Follow",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Middle: small cover + song info (+ optional description)
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
                              if ((widget.description ?? '').isNotEmpty)
                                Text(
                                  widget.description!,
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

                    // Bottom: like + share
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
                          onPressed: widget.onShare,
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
        ),
      ),
    );
  }
}



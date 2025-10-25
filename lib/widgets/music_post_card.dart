import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final VoidCallback? onOpenInSpotify;
  final VoidCallback? onUserTap;

  final bool showFollowButton;
  final bool showUserInfo;
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
    this.onOpenInSpotify,
    this.onUserTap,
    this.showFollowButton = false,
    this.showUserInfo = true,
    this.height = 180,
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
        child: Container(
          constraints: BoxConstraints(
            minHeight: widget.height,
            maxHeight: widget.height + 20, // Allow some flexibility
          ),
          width: double.infinity,
          child: Stack(
            children: [
              // Blurred background cover
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: CachedNetworkImage(
                    imageUrl: widget.coverUrl,
                    fit: BoxFit.cover,
                    memCacheWidth:
                        400, // Reduce memory usage for blurred background
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ),
              // Dark overlay with gradient to improve contrast
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(widget.overlayOpacity * 0.7),
                          Colors.black.withOpacity(widget.overlayOpacity * 1.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Foreground content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Top row: avatar + username | time | optional follow
                    if (widget.showUserInfo)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: widget.avatarVerticalPadding,
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  CachedNetworkImageProvider(widget.avatarUrl),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onUserTap,
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
                          ),
                          Text(
                            widget.timeAgo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          if (widget.showFollowButton) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: widget.onFollowPressed,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.15),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text(
                                "Follow",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ]
                        ],
                      )
                    else
                      // Just show time when user info is hidden
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            widget.timeAgo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Middle: small cover + song info (+ optional description)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover image with fixed size and shadow
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: widget.coverUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.coverUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    memCacheWidth:
                                        120, // 2x for retina displays
                                    memCacheHeight: 120,
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    placeholder: (context, url) => Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white70,
                                        size: 24,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white70,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Song info with flexible layout
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(height: 1),
                              Text(
                                widget.artist,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((widget.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.description!,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Bottom: like + share + spotify
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
                        const SizedBox(width: 4),
                        Text(
                          "$likes",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: widget.onOpenInSpotify,
                          icon: const Icon(
                            Icons.music_note,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
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

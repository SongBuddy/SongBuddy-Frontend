import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_colors.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // richer dummy data with likes & timestamp
    final dummyPosts = [
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
            "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
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
            "https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2",
        "description": "Makes me feel nostalgic ✨",
        "likes": 211,
        "time": "1d"
      },
    ];

    return Scaffold(
      // Gradient background for depth & modern look
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071028), // deep navy
              Color(0xFF0B0B0D), // near-black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar (more modern / centered)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // small profile avatar on left
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          NetworkImage(dummyPosts[0]["avatarUrl"] as String),
                      backgroundColor: Colors.transparent,
                    ),
                    const Spacer(),
                    // Title with subtle glow
                    Text(
                      "SongBuddy",
                      style: TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.03),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    // notification icon with subtle badge
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white70),
                        ),
                        Positioned(
                          right: 8,
                          top: 10,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

// Search bar with premium glass effect
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Focus(
                      onFocusChange: (hasFocus) {
                        // You could trigger animations if needed
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF5EEAD4).withOpacity(0.15),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: TextField(
                              style: const TextStyle(color: Colors.black),
                              cursorColor: const Color(0xFF5EEAD4),
                              decoration: InputDecoration(
                                hintText: "🔍  Search users, songs, playlists",
                                hintStyle:
                                    const TextStyle(color: Colors.black),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70),
                                suffixIcon: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.mic_rounded,
                                      color: Colors.white70, size: 22),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Suggestion chips below (unchanged)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          SizedBox(width: 6),
                          _SuggestionChip(label: "For you"),
                          _SuggestionChip(label: "Pop"),
                          _SuggestionChip(label: "Chill"),
                          _SuggestionChip(label: "Trending"),
                          _SuggestionChip(label: "New"),
                          SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Feed
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 18),
                  itemCount: dummyPosts.length,
                  itemBuilder: (context, index) {
                    final post = dummyPosts[index];
                    return _MusicPostCard(
                      index: index,
                      username: post["username"] as String,
                      avatarUrl: post["avatarUrl"] as String,
                      trackTitle: post["trackTitle"] as String,
                      artist: post["artist"] as String,
                      coverUrl: post["coverUrl"] as String,
                      description: post["description"] as String,
                      initialLikes: post["likes"] as int,
                      timeAgo: post["time"] as String,
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

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}

class _MusicPostCard extends StatefulWidget {
  final int index;
  final String username;
  final String avatarUrl;
  final String trackTitle;
  final String artist;
  final String coverUrl;
  final String description;
  final int initialLikes;
  final String timeAgo;

  const _MusicPostCard({
    required this.index,
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
  State<_MusicPostCard> createState() => _MusicPostCardState();
}

class _MusicPostCardState extends State<_MusicPostCard>
    with TickerProviderStateMixin {
  bool isLiked = false;
  late int likeCount;
  bool showHeartOverlay = false;

  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  late AnimationController _likePopController;

  @override
  void initState() {
    super.initState();
    likeCount = widget.initialLikes;

    // Entry animation per item (staggered by index)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);

    // start with a slight delay based on index for stagger
    Future.delayed(Duration(milliseconds: 80 * (widget.index)), () {
      if (mounted) _entryController.forward();
    });

    // like pop animation
    _likePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _likePopController.dispose();
    super.dispose();
  }

  void _handleLike({bool fromDoubleTap = false}) {
    setState(() {
      isLiked = true;
      likeCount = likeCount + (isLiked ? 1 : 0);
    });

    // run pop animation
    _likePopController.forward(from: 0.0);

    // if triggered by double tap show heart overlay briefly
    if (fromDoubleTap) {
      setState(() => showHeartOverlay = true);
      Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => showHeartOverlay = false);
      });
    }
  }

  void _toggleLikeButton() {
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : (likeCount > 0 ? likeCount - 1 : 0);
    });
    // small pop when tapping like icon
    _likePopController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Accent color (tweak as needed)
    const accent = Color(0xFF5EEAD4); // mint accent — modern & readable on dark
    final cardRadius = 18.0;

    return FadeTransition(
      opacity: _entryAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
            .animate(_entryAnim),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            children: [
              // Gradient border / soft glow behind card for premium feel
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius + 6),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.02),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: accent.withOpacity(0.02),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

              // Glassmorphism card
              ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header: avatar, username, time, follow
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(widget.avatarUrl,
                                      fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "• ${widget.timeAgo}",
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.04),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.artist,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Music",
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.06),
                                  foregroundColor: accent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text("Follow"),
                              )
                            ],
                          ),
                        ),

                        // cover image with overlay & double-tap
                        GestureDetector(
                          onDoubleTap: () {
                            if (!isLiked) _handleLike(fromDoubleTap: true);
                            // show a small ripple / visual handled by showHeartOverlay
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // cover
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    height: 240,
                                    width: double.infinity,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // cover image
                                        Image.network(
                                          widget.coverUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: Colors.white
                                                  .withOpacity(0.03),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white24),
                                              ),
                                            );
                                          },
                                        ),

                                        // subtle vignette
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.6),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // floating small play control (glass)
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8, sigmaY: 8),
                                      child: InkWell(
                                        onTap: () {},
                                        child: Container(
                                          height: 52,
                                          width: 52,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0x66FFFFFF),
                                                Color(0x30FFFFFF)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.08)),
                                          ),
                                          child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 28),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // track title bottom-left
                              Positioned(
                                left: 28,
                                bottom: 26,
                                right: 28,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.trackTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.artist,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    )
                                  ],
                                ),
                              ),

                              // heart overlay on double tap
                              AnimatedOpacity(
                                opacity: showHeartOverlay ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 260),
                                child: ScaleTransition(
                                  scale: Tween(begin: 0.8, end: 1.15).animate(
                                    CurvedAnimation(
                                        parent: _likePopController,
                                        curve: Curves.elasticOut),
                                  ),
                                  child: Icon(Icons.favorite,
                                      color: Colors.white.withOpacity(0.92),
                                      size: 86),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // description
                        if (widget.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Text(
                              widget.description,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13.5),
                            ),
                          ),

                        // interactions + subtle progress UI
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          child: Row(
                            children: [
                              // like button with animated pop
                              GestureDetector(
                                onTap: _toggleLikeButton,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.18)
                                      .animate(
                                    CurvedAnimation(
                                        parent: _likePopController,
                                        curve: Curves.elasticOut),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? Colors.redAccent.withOpacity(0.14)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked
                                          ? Colors.redAccent
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text("$likeCount",
                                  style:
                                      const TextStyle(color: Colors.white70)),

                              const SizedBox(width: 14),

                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.comment_outlined,
                                    color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.share_outlined,
                                    color: Colors.white70),
                              ),

                              const Spacer(),

                              // mini progress (decorative)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 110,
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.white12,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: 0.36,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [
                                                    accent,
                                                    Color(0xFF3DDC97)
                                                  ]),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // more menu
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

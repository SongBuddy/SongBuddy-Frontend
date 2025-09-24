import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/widgets/music_post_card.dart';

class UserProfileScreen extends StatelessWidget {
  final String username;
  final String avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data
    final nowPlaying = {
      'track': 'Blinding Lights',
      'artist': 'The Weeknd',
    };

    final topArtists = ['Drake', 'The Weeknd', 'Billie Eilish', 'Kendrick Lamar'];
    final topTracks = ['Sunflower', 'Starboy', 'Bad Guy', 'God’s Plan'];

    final userPosts = [
      {
        'track': 'Midnight City',
        'artist': 'M83',
        'desc': 'Perfect track for late night vibes.',
        'cover': 'https://i.scdn.co/image/ab67616d0000b2734f1b5b0b8b8b8b8b8b8b8b8b8',
        'timeAgo': '2h ago',
        'likes': 12,
        'isLiked': false,
      },
      {
        'track': 'Sunflower',
        'artist': 'Post Malone',
        'desc': 'Always lifts my mood.',
        'cover': 'https://i.scdn.co/image/ab67616d0000b2734f1b5b0b8b8b8b8b8b8b8b8b8',
        'timeAgo': '5h ago',
        'likes': 8,
        'isLiked': true,
      },
      {
        'track': 'Heat Waves',
        'artist': 'Glass Animals',
        'desc': 'Such a vibe 🔥',
        'cover': 'https://i.scdn.co/image/ab67616d0000b2734f1b5b0b8b8b8b8b8b8b8b8b8',
        'timeAgo': '1d ago',
        'likes': 24,
        'isLiked': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildTopBar(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    // Add refresh logic here if needed
                    HapticFeedback.selectionClick();
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [

                      // Follow button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentMint,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: Text(
                              "Follow",
                              style: AppTextStyles.bodyOnDark.copyWith(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBackgroundStart,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats section
                      _buildStats(context),
                      const SizedBox(height: 24),

                      // Now playing section
                      _buildSectionTitle("Now Playing"),
                      if (nowPlaying.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _GlassCard(
                            child: ListTile(
                              leading: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                              title: Text(
                                nowPlaying['track']!,
                                style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                nowPlaying['artist']!,
                                style: AppTextStyles.captionOnDark,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Top artists
                      _buildSectionTitle("Top Artists"),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppColors.onDarkPrimary.withOpacity(0.12),
                                  child: Text(
                                    topArtists[index][0].toUpperCase(),
                                    style: AppTextStyles.heading2OnDark.copyWith(
                                      fontSize: 24,
                                      color: AppColors.accentMint,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    topArtists[index],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.captionOnDark,
                                  ),
                                )
                              ],
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: topArtists.length,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Top tracks
                      _buildSectionTitle("Top Tracks"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topTracks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: _GlassCard(
                              child: ListTile(
                                leading: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                                title: Text(
                                  topTracks[index],
                                  style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Posts
                      _buildSectionTitle("Posts"),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userPosts.length,
                        itemBuilder: (context, index) {
                          final post = userPosts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: MusicPostCard(
                              username: '', // Empty username to hide user info
                              avatarUrl: '', // Empty avatar URL to hide user info
                              trackTitle: post['track'] as String,
                              artist: post['artist'] as String,
                              coverUrl: post['cover'] as String,
                              timeAgo: post['timeAgo'] as String,
                              description: post['desc'] as String?,
                              initialLikes: post['likes'] as int,
                              isInitiallyLiked: post['isLiked'] as bool,
                              showUserInfo: false, // Hide username and avatar
                              onLikeChanged: (isLiked, likes) {
                                // TODO: Implement like functionality
                                print('Like changed: $isLiked, likes: $likes');
                              },
                              onCardTap: () {
                                // TODO: Implement post tap functionality
                                print('Post tapped: ${post['track']}');
                              },
                              onShare: () {
                                // TODO: Implement share functionality
                                print('Share post: ${post['track']}');
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.person_outline, color: AppColors.onDarkSecondary),
        ),
        const Spacer(),
        Text(
          username,
          style: AppTextStyles.heading2OnDark.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: AppColors.onDarkPrimary.withOpacity(0.03),
                blurRadius: 6,
              )
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert, color: AppColors.onDarkSecondary),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    // Mock data for user profile stats
    const savedTracksTotal = 1247;
    const playlistsTotal = 23;
    const country = 'US';
    const product = 'premium';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;
          final chips = [
            _StatChip(icon: Icons.library_music, label: 'Saved', value: savedTracksTotal.toString()),
            _StatChip(icon: Icons.queue_music, label: 'Playlists', value: playlistsTotal.toString()),
            _StatChip(icon: Icons.flag, label: 'Country', value: country),
            _StatChip(icon: Icons.workspace_premium, label: 'Plan', value: product),
          ];
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: chips
                .map((c) => SizedBox(
                      width: isNarrow ? (constraints.maxWidth / 2) - 12 : (constraints.maxWidth / 4) - 12,
                      child: c,
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppTextStyles.heading2OnDark),
    );
  }
}

// Glassmorphism card helper (matching ProfileScreen feel)
class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const _GlassCard({required this.child, this.borderRadius = 14});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onDarkPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.accentMint),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600)),
                  Text(label, style: AppTextStyles.captionOnDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

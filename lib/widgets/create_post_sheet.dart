import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/screens/create_post_screen.dart';

Future<bool?> showCreatePostSheet(
  BuildContext context, {
  required Map<String, dynamic>? nowPlaying,
  required List<Map<String, dynamic>> topTracks,
  required List<Map<String, dynamic>> recentPlayed,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _CreatePostSheet(
        nowPlaying: nowPlaying,
        topTracks: topTracks,
        recentPlayed: recentPlayed,
      );
    },
  );
}

class _CreatePostSheet extends StatefulWidget {
  final Map<String, dynamic>? nowPlaying;
  final List<Map<String, dynamic>> topTracks;
  final List<Map<String, dynamic>> recentPlayed;

  const _CreatePostSheet({
    required this.nowPlaying,
    required this.topTracks,
    required this.recentPlayed,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(20);
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: radius, topRight: radius),
      child: Container(
        color: AppColors.darkBackgroundEnd,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.onDarkPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text('Create post', style: AppTextStyles.heading2OnDark.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onDarkPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.onDarkSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Now Playing'),
                  Tab(text: 'Top Tracks'),
                  Tab(text: 'Recent'),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNowPlayingTab(context),
                    _buildTopTracksTab(context),
                    _buildRecentTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingTab(BuildContext context) {
    final item = widget.nowPlaying?['item'] as Map<String, dynamic>?;
    if (item == null) {
      return _buildEmpty('Nothing is playing right now');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _trackTile(
          title: item['name'] as String? ?? '',
          subtitle: _joinArtists(item['artists'] as List<dynamic>?),
          imageUrl: _albumImage(item['album'] as Map<String, dynamic>?),
          onTap: () => _goToCreatePost(context, item, item['id'] as String? ?? ''),
        ),
      ],
    );
  }

  Widget _buildTopTracksTab(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final track = widget.topTracks[index];
        return _trackTile(
          title: track['name'] as String? ?? '',
          subtitle: _joinArtists(track['artists'] as List<dynamic>?),
          imageUrl: _albumImage(track['album'] as Map<String, dynamic>?),
          onTap: () => _goToCreatePost(context, track, track['id'] as String? ?? ''),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: widget.topTracks.length > 25 ? 25 : widget.topTracks.length,
    );
  }

  Widget _buildRecentTab(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = widget.recentPlayed[index];
        final track = item['track'] as Map<String, dynamic>? ?? const {};
        return _trackTile(
          title: track['name'] as String? ?? '',
          subtitle: _joinArtists(track['artists'] as List<dynamic>?),
          imageUrl: _albumImage(track['album'] as Map<String, dynamic>?),
          onTap: () => _goToCreatePost(context, track, track['id'] as String? ?? ''),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: widget.recentPlayed.length > 25 ? 25 : widget.recentPlayed.length,
    );
  }

  Widget _trackTile({
    required String title,
    required String subtitle,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.08)),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: AppColors.onDarkPrimary.withOpacity(0.12),
                    child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                  ),
          ),
          title: Text(title, style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppTextStyles.captionOnDark),
          trailing: const Icon(Icons.chevron_right, color: AppColors.onDarkSecondary),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(message, style: AppTextStyles.bodyOnDark.copyWith(color: AppColors.onDarkSecondary)),
      ),
    );
  }

  String? _albumImage(Map<String, dynamic>? album) {
    final images = album?['images'] as List<dynamic>? ?? const [];
    if (images.isEmpty) return null;
    return (images.last['url'] as String?);
  }

  String _joinArtists(List<dynamic>? artists) {
    final names = (artists ?? const [])
        .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return names.isEmpty ? '' : names.join(', ');
  }

  void _goToCreatePost(BuildContext context, Map<String, dynamic> track, String trackId) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          selectedTrack: track,
          selectedTrackId: trackId,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // Propagate success up to the bottom sheet caller
        Navigator.pop(context, true);
      }
    });
  }
}



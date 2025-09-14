import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/spotify_service.dart';
import 'package:songbuddy/widgets/spotify_login_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthProvider _authProvider;
  late final SpotifyService _spotifyService;

  bool _initialized = false;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _currentlyPlaying; // can be null when 204
  int? _savedTracksTotal;
  int? _playlistsTotal;
  List<Map<String, dynamic>> _topArtists = const [];
  List<Map<String, dynamic>> _topTracks = const [];

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _spotifyService = SpotifyService();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authProvider.initialize();
      _authProvider.addListener(_onAuthChanged);
      _initialized = true;
      if (_authProvider.isAuthenticated) {
        await _fetchAll();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _authProvider.removeListener(_onAuthChanged);
    }
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _fetchAll() async {
    if (!_authProvider.isAuthenticated || _authProvider.accessToken == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = _authProvider.accessToken!;
    try {
      final results = await Future.wait([
        _spotifyService.getCurrentUser(token),
        _spotifyService.getCurrentlyPlaying(token),
        _spotifyService.getUserSavedTracks(token, limit: 1),
        _spotifyService.getUserPlaylists(token, limit: 1),
        _spotifyService.getUserTopArtists(token, limit: 10),
        _spotifyService.getUserTopTracks(token, limit: 10),
      ]);

      final user = results[0] as Map<String, dynamic>;
      final currentlyPlaying = results[1] as Map<String, dynamic>?;
      final savedTracks = results[2] as Map<String, dynamic>;
      final playlists = results[3] as Map<String, dynamic>;
      final topArtists = results[4] as Map<String, dynamic>;
      final topTracks = results[5] as Map<String, dynamic>;

      setState(() {
        _user = user;
        _currentlyPlaying = currentlyPlaying;
        _savedTracksTotal = savedTracks['total'] as int?;
        _playlistsTotal = playlists['total'] as int?;
        _topArtists = (topArtists['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        _topTracks = (topTracks['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleConnect() async {
    await _authProvider.login();
    if (_authProvider.isAuthenticated) {
      await _fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Connect your Spotify to see your profile',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SpotifyLoginButton(
                  onPressed: _handleConnect,
                  text: 'Connect Spotify',
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildSectionTitle('Currently Playing')),
            SliverToBoxAdapter(child: _buildCurrentlyPlaying()),
            SliverToBoxAdapter(child: _buildSectionTitle('Top Artists')),
            _buildTopArtists(),
            SliverToBoxAdapter(child: _buildSectionTitle('Top Tracks')),
            _buildTopTracks(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader() {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    final displayName = _user?['display_name'] as String? ?? 'Spotify User';
    final email = _user?['email'] as String?;
    final followers = _user?['followers']?['total'] as int?;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4C46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 44)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.heading1.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: AppTextStyles.caption.copyWith(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (followers != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                '$followers followers',
                                style: AppTextStyles.caption.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Profile'),
      ),
    );
  }

  Widget _buildStats() {
    final country = _user?['country'] as String?;
    final product = _user?['product'] as String?; // premium/free

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _StatChip(icon: Icons.library_music, label: 'Saved', value: _savedTracksTotal?.toString() ?? '—'),
          const SizedBox(width: 8),
          _StatChip(icon: Icons.queue_music, label: 'Playlists', value: _playlistsTotal?.toString() ?? '—'),
          const SizedBox(width: 8),
          _StatChip(icon: Icons.flag, label: 'Country', value: country ?? '—'),
          const SizedBox(width: 8),
          _StatChip(icon: Icons.workspace_premium, label: 'Plan', value: product ?? '—'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppTextStyles.heading2),
    );
  }

  Widget _buildCurrentlyPlaying() {
    final item = _currentlyPlaying?['item'] as Map<String, dynamic>?;
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.play_circle_outline,
          title: 'Nothing playing right now',
          subtitle: 'Start a song on Spotify to see it here.',
        ),
      );
    }

    final name = item['name'] as String? ?? '';
    final artists = (item['artists'] as List<dynamic>? ?? const [])
        .map((a) => a['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final images = item['album']?['images'] as List<dynamic>? ?? const [];
    final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null; // smaller image

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.music_note),
                  ),
          ),
          title: Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(artists, style: AppTextStyles.caption),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTopArtists() {
    if (_topArtists.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EmptyCard(
            icon: Icons.person_outline,
            title: 'No top artists yet',
            subtitle: 'Listen more to build your top artists.',
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final artist = _topArtists[index];
            final images = (artist['images'] as List<dynamic>? ?? const []);
            final url = images.isNotEmpty ? images.first['url'] as String? : null;
            return Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: url != null ? NetworkImage(url) : null,
                  child: url == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    artist['name'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                )
              ],
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: _topArtists.length,
        ),
      ),
    );
  }

  SliverList _buildTopTracks() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _topTracks.length) return const SizedBox.shrink();
          final track = _topTracks[index];
          final images = track['album']?['images'] as List<dynamic>? ?? const [];
          final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
          final artists = (track['artists'] as List<dynamic>? ?? const [])
              .map((a) => a['name'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.music_note),
                        ),
                ),
                title: Text(track['name'] as String? ?? ''),
                subtitle: Text(artists, style: AppTextStyles.caption),
                trailing: Text('#${index + 1}'),
              ),
            ),
          );
        },
        childCount: _topTracks.length,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  Text(label, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


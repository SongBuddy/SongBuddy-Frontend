import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _recentlyPlayed = const [];
  bool _insufficientScopeTop = false;

  // Time range state for Top Artists/Tracks: short_term (4 weeks), medium_term (6 months), long_term (all-time)
  final List<String> _timeRanges = const ['short_term', 'medium_term', 'long_term'];
  int _timeRangeIndex = 1; // default to medium_term
  bool _loadingTop = false; // non-blocking loading for top artists/tracks
  static const Duration _animDur = Duration(milliseconds: 250);

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
    // ignore: avoid_print
    print('[Profile] Fetch start');
    try {
      // User profile (required)
      final user = await _spotifyService.getCurrentUser(token);
      // Optional parallel calls with individual handling
      final futures = <Future<void>>[
        () async {
          try {
            _currentlyPlaying = await _spotifyService.getCurrentlyPlaying(token);
          } catch (e) {
            // ignore
          }
        }(),
        () async {
          try {
            final saved = await _spotifyService.getUserSavedTracks(token, limit: 1);
            _savedTracksTotal = saved['total'] as int?;
          } catch (e) {}
        }(),
        () async {
          try {
            final pls = await _spotifyService.getUserPlaylists(token, limit: 1);
            _playlistsTotal = pls['total'] as int?;
          } catch (e) {}
        }(),
        () async {
          try {
            final ta = await _spotifyService.getUserTopArtists(
              token,
              timeRange: _timeRanges[_timeRangeIndex],
              limit: 10,
            );
            _topArtists = (ta['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {
            _insufficientScopeTop = true;
            _topArtists = const [];
          }
        }(),
        () async {
          try {
            final tt = await _spotifyService.getUserTopTracks(
              token,
              timeRange: _timeRanges[_timeRangeIndex],
              limit: 10,
            );
            _topTracks = (tt['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {
            _insufficientScopeTop = true;
            _topTracks = const [];
          }
        }(),
        () async {
          try {
            final rp = await _spotifyService.getRecentlyPlayed(token, limit: 10);
            _recentlyPlayed = (rp['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {}
        }(),
      ];
      await Future.wait(futures);

      setState(() {
        _user = user;
      });
      // ignore: avoid_print
      print('[Profile] Fetch success: user=${user['id']} topArtists=${_topArtists.length} topTracks=${_topTracks.length} recently=${_recentlyPlayed.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      // ignore: avoid_print
      print('[Profile] Fetch error: $e');
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

  Future<void> _updateTimeRange(int index) async {
    if (index == _timeRangeIndex) return;
    if (!_authProvider.isAuthenticated || _authProvider.accessToken == null) return;
    setState(() {
      _timeRangeIndex = index;
      _loadingTop = true;
      _insufficientScopeTop = false;
    });
    final token = _authProvider.accessToken!;
    try {
      final results = await Future.wait([
        _spotifyService.getUserTopArtists(
          token,
          timeRange: _timeRanges[_timeRangeIndex],
          limit: 10,
        ),
        _spotifyService.getUserTopTracks(
          token,
          timeRange: _timeRanges[_timeRangeIndex],
          limit: 10,
        ),
      ]);
      final topArtistsResp = results[0] as Map<String, dynamic>;
      final topTracksResp = results[1] as Map<String, dynamic>;
      setState(() {
        _topArtists = (topArtistsResp['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
        _topTracks = (topTracksResp['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _insufficientScopeTop = true;
        _topArtists = const [];
        _topTracks = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTop = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
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
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await _fetchAll();
          HapticFeedback.selectionClick();
        },
        child: CustomScrollView(
          slivers: _loading
              ? _buildSkeletonSlivers(context)
              : [
                  _buildHeader(context),
                  SliverToBoxAdapter(child: _buildStats(context)),
                  SliverToBoxAdapter(child: _buildSectionTitle('Currently Playing')),
                  SliverToBoxAdapter(child: _buildCurrentlyPlaying()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Top Artists')),
                  SliverToBoxAdapter(child: _buildTimeRangeToggle()),
                  _buildTopArtists(),
                  SliverToBoxAdapter(child: _buildSectionTitle('Top Tracks')),
                  (_loadingTop ? _buildTopTracksSkeleton(context) : _buildTopTracks(context)),
                  SliverToBoxAdapter(child: _buildSectionTitle('Recently Played')),
                  _buildRecentlyPlayed(),
                  if (_insufficientScopeTop)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyCard(
                          icon: Icons.lock_outline,
                          title: 'Limited data due to permissions',
                          subtitle: 'Re-connect and grant access to Top Artists/Tracks to see more.',
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    final displayName = _user?['display_name'] as String? ?? 'Spotify User';
    final email = _user?['email'] as String?;
    final followers = _user?['followers']?['total'] as int?;

    return SliverAppBar(
      pinned: true,
      expandedHeight: MediaQuery.of(context).size.height * 0.28,
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
                    radius: MediaQuery.of(context).size.width < 360 ? 36 : 44,
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

  Widget _buildStats(BuildContext context) {
    final country = _user?['country'] as String?;
    final product = _user?['product'] as String?; // premium/free

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;
          final chips = [
            _StatChip(icon: Icons.library_music, label: 'Saved', value: _savedTracksTotal?.toString() ?? '—'),
            _StatChip(icon: Icons.queue_music, label: 'Playlists', value: _playlistsTotal?.toString() ?? '—'),
            _StatChip(icon: Icons.flag, label: 'Country', value: country ?? '—'),
            _StatChip(icon: Icons.workspace_premium, label: 'Plan', value: product ?? '—'),
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
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: _animDur,
        child: _loadingTop
            ? _buildTopArtistsSkeletonContent(key: const ValueKey('artists-skeleton'))
            : (_topArtists.isEmpty
                ? Padding(
                    key: const ValueKey('artists-empty'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyCard(
                      icon: Icons.person_outline,
                      title: 'No top artists yet',
                      subtitle: 'Listen more to build your top artists.',
                    ),
                  )
                : _buildTopArtistsContent(key: const ValueKey('artists-list'))),
      ),
    );
  }

  Widget _buildTopArtistsContent({Key? key}) {
    return SizedBox(
      key: key,
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
    );
  }

  Widget _buildTopArtistsSkeletonContent({Key? key}) {
    return SizedBox(
      key: key,
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => const _SkeletonCircle(diameter: 72),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 6,
      ),
    );
  }

  Widget _buildTimeRangeToggle() {
    final labels = const ['4w', '6m', 'All'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(12),
        isSelected: List<bool>.generate(3, (i) => i == _timeRangeIndex),
        onPressed: (int i) {
          HapticFeedback.selectionClick();
          _updateTimeRange(i);
        },
        children: labels
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(t, style: AppTextStyles.body),
                ))
            .toList(),
      ),
    );
  }

  SliverGrid _buildTopTracks(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCountForWidth(MediaQuery.of(context).size.width),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null
                        ? Image.network(imageUrl!, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade300, child: const Icon(Icons.music_note)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  artists,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        },
        childCount: _topTracks.length,
      ),
    );
  }

  SliverGrid _buildTopTracksSkeleton(BuildContext context) {
    final gridCount = _gridCountForWidth(MediaQuery.of(context).size.width);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(width: double.infinity, height: 140, radius: 12),
                SizedBox(height: 8),
                _SkeletonBox(width: 120, height: 14, radius: 6),
                SizedBox(height: 6),
                _SkeletonBox(width: 80, height: 12, radius: 6),
              ],
            ),
          );
        },
        childCount: gridCount * 2,
      ),
    );
  }

  int _gridCountForWidth(double width) {
    if (width >= 1024) return 5;
    if (width >= 800) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  List<Widget> _buildSkeletonSlivers(BuildContext context) {
    final gridCount = _gridCountForWidth(MediaQuery.of(context).size.width);
    return [
      _skeletonHeader(),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (_) => const _SkeletonBox(width: 160, height: 54, radius: 12)),
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Currently Playing')),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const _SkeletonTile(),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Top Artists')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => const _SkeletonCircle(diameter: 72),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 6,
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Top Tracks')),
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(width: double.infinity, height: 140, radius: 12),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 14, radius: 6),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 80, height: 12, radius: 6),
                ],
              ),
            );
          },
          childCount: gridCount * 2,
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Recently Played')),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const _SkeletonTile(),
          ),
          childCount: 6,
        ),
      ),
    ];
  }

  SliverList _buildRecentlyPlayed() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _recentlyPlayed.length) return const SizedBox.shrink();
          final item = _recentlyPlayed[index];
          final track = item['track'] as Map<String, dynamic>? ?? const {};
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
              ),
            ),
          );
        },
        childCount: _recentlyPlayed.length,
      ),
    );
  }

  SliverToBoxAdapter _skeletonHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
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
              children: const [
                _SkeletonCircle(diameter: 88),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 180, height: 22, radius: 6),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 140, height: 14, radius: 6),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 120, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    return Container(
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

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double diameter;
  const _SkeletonCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: const [
            _SkeletonBox(width: 56, height: 56, radius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 180, height: 14, radius: 6),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 12, radius: 6),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            final gradient = LinearGradient(
              begin: Alignment(-1.0 - 3 * _controller.value, 0.0),
              end: Alignment(1.0 + 3 * _controller.value, 0.0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.25, 0.5, 0.75],
            );
            return gradient.createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}


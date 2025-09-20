import 'dart:ui';
import 'package:flutter/material.dart';

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
        'desc': 'Perfect track for late night vibes.'
      },
      {
        'track': 'Sunflower',
        'artist': 'Post Malone',
        'desc': 'Always lifts my mood.'
      },
      {
        'track': 'Heat Waves',
        'artist': 'Glass Animals',
        'desc': 'Such a vibe 🔥'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile header
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black54),
                  ],
                ),
                title: Text(username, style: const TextStyle(color: Colors.white)),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                )
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Follow button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Follow",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Now playing section
                    _buildSectionTitle("Now Playing"),
                    if (nowPlaying.isNotEmpty)
                      _buildGlassCard(
                        child: ListTile(
                          leading: const Icon(Icons.music_note, color: Colors.white),
                          title: Text(
                            nowPlaying['track']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            nowPlaying['artist']!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Top artists
                    _buildSectionTitle("Top Artists"),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topArtists.length,
                        itemBuilder: (context, index) {
                          return _buildGlassCard(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Center(
                              child: Text(
                                topArtists[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top tracks
                    _buildSectionTitle("Top Tracks"),
                    Column(
                      children: topTracks
                          .map((track) => _buildGlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.music_note, color: Colors.white),
                                  title: Text(track, style: const TextStyle(color: Colors.white)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Posts
                    _buildSectionTitle("Posts"),
                    Column(
                      children: userPosts
                          .map((post) => _buildGlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.album, color: Colors.white),
                                  title: Text(
                                    post['track']!,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "${post['artist']} • ${post['desc']}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    double? width,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

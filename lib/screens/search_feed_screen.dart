import 'dart:ui';
import 'package:flutter/material.dart';

class SearchFeedScreen extends StatefulWidget {
  const SearchFeedScreen({super.key});

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen>
    with SingleTickerProviderStateMixin {
  String query = '';
  final TextEditingController _controller = TextEditingController();

  // Mock data for demonstration
  final List<Map<String, dynamic>> users = [
    {'username': 'Alice', 'followers': 120, 'avatar': Icons.person},
    {'username': 'Bob', 'followers': 95, 'avatar': Icons.person},
    {'username': 'Charlie', 'followers': 230, 'avatar': Icons.person},
  ];

  final List<Map<String, dynamic>> posts = [
    {
      'track': 'Midnight City',
      'artist': 'M83',
      'user': 'Alice',
      'desc': 'Perfect track for late night vibes.',
      'coverUrl':
          'https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2', // Replace with real album art
    },
    {
      'track': 'Blinding Lights',
      'artist': 'The Weeknd',
      'user': 'Bob',
      'desc': 'Still one of my favorites!',
      'coverUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s',
    },
    {
      'track': 'Sunflower',
      'artist': 'Post Malone',
      'user': 'Charlie',
      'desc': 'Always lifts my mood.',
      'coverUrl': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF0Jqpe95kORYuGnJhSprCr8KG_WtwW8oS9Q&ss',
    },
  ];

  List<Map<String, dynamic>> get filteredUsers {
    if (query.isEmpty) return [];
    return users
        .where((u) => u['username'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Map<String, dynamic>> get filteredPosts {
    if (query.isEmpty) return [];
    return posts
        .where((p) => p['track'].toLowerCase().contains(query.toLowerCase()) ||
            p['artist'].toLowerCase().contains(query.toLowerCase()) ||
            p['desc'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Widget _buildMusicPost(Map<String, dynamic> post) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background: album art blurred
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              post['coverUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          // Foreground: glass card overlay
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post['coverUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(post['track'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(post['artist'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      Text("${post['user']}: ${post['desc']}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            radius: 28,
            child: Icon(user['avatar'], color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(user['username'], style: const TextStyle(color: Colors.white)),
          Text('${user['followers']} followers',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users or genres...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    query = val;
                  });
                },
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: ListView(
                  key: ValueKey(query),
                  children: [
                    if (filteredUsers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Users',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: filteredUsers
                                    .map((user) => _buildUserCard(user))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (filteredPosts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Music Posts',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Column(
                              children: filteredPosts
                                  .map((post) => _buildMusicPost(post))
                                  .toList(),
                            )
                          ],
                        ),
                      ),

                    // Random discovery
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Random Discovery',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: posts.map((post) {
                              return _buildMusicPost(post);
                            }).toList(),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

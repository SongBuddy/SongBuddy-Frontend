import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/screens/user_profile_screen.dart';
import 'package:songbuddy/widgets/music_post_card.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/providers/auth_provider.dart';

class SearchFeedScreen extends StatefulWidget {
  const SearchFeedScreen({super.key});

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen> {
  String query = '';
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _searchFocusNode;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSearching = false;

  // Backend services
  late final BackendService _backendService;
  late final AuthProvider _authProvider;

  // Track likes for posts
  final Map<int, bool> _likedPosts = {};
  final Map<int, int> _likeCounts = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _searchFocusNode = FocusNode();
    _backendService = BackendService();
    _authProvider = AuthProvider();
    _searchFocusNode.addListener(_onFocusChange);

    _controller.addListener(() {
      final t = _controller.text;
      if (t != query) {
        setState(() {
          query = t;
          _isSearching = true;
        });
      }
    });

    // Initialize like counts
    for (int i = 0; i < posts.length; i++) {
      _likedPosts[i] = false;
      _likeCounts[i] = 0;
    }
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() => _isSearching = true);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _controller.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (!available) return;

      _searchFocusNode.requestFocus();
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          final recognized = result.recognizedWords;
          setState(() {
            query = recognized;
            _controller.text = recognized;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            _isSearching = true;
          });
        },
        listenMode: stt.ListenMode.search,
        partialResults: true,
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  final List<Map<String, dynamic>> users = [
    {'username': 'Alice', 'followers': 120, 'avatar': Icons.person},
    {'username': 'Alex', 'followers': 310, 'avatar': Icons.person},
    {'username': 'Adam', 'followers': 200, 'avatar': Icons.person},
    {'username': 'Bob', 'followers': 95, 'avatar': Icons.person},
    {'username': 'Charlie', 'followers': 230, 'avatar': Icons.person},
    {'username': 'Eve', 'followers': 200, 'avatar': Icons.person},
  ];

  final List<Map<String, dynamic>> posts = [
    {
      'track': 'Midnight City',
      'artist': 'M83',
      'user': 'Alice',
      'desc': 'Perfect track for late night vibes.',
      'coverUrl':
          'https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2',
      'time': '7h',
    },
    {
      'track': 'Blinding Lights',
      'artist': 'The Weeknd',
      'user': 'Bob',
      'desc': 'Still one of my favorites!',
      'coverUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s',
      'time': '12h',
    },
    {
      'track': 'Sunflower',
      'artist': 'Post Malone',
      'user': 'Charlie',
      'desc': 'Always lifts my mood.',
      'coverUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF0Jqpe95kORYuGnJhSprCr8KG_WtwW8oS9Q&ss',
      'time': '1d',
    },
  ];

  List<Map<String, dynamic>> get filteredUsers {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return users
        .where((u) => (u['username'] as String).toLowerCase().startsWith(q))
        .toList();
  }

  Widget _buildSuggestionDropdown() {
    final suggestions = filteredUsers;
    if (suggestions.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text("No users found", style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
        itemBuilder: (context, idx) {
          final u = suggestions[idx];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(u['avatar'], color: Colors.white),
            ),
            title: Text(u['username'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${u['followers']} followers',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              _searchFocusNode.unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    username: u['username'] as String,
                    avatarUrl: "https://i.pravatar.cc/150?img=1",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMusicPost(Map<String, dynamic> post, int index) {
    final username = post['user'] as String;
    final likeCount = _likeCounts[index] ?? 0;
    final isLiked = _likedPosts[index] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MusicPostCard(
        username: username,
        avatarUrl: "https://i.pravatar.cc/150?img=3",
        trackTitle: post['track'] as String,
        artist: post['artist'] as String,
        coverUrl: post['coverUrl'] as String,
        timeAgo: post['time'] as String,
        description: post['desc'] as String,
        height: 190,
        borderRadius: 20,
        overlayOpacity: 0.36,
        initialLikes: likeCount,
        isInitiallyLiked: isLiked,
        showFollowButton: true,
        onCardTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                username: username,
                avatarUrl: "https://i.pravatar.cc/150?img=1",
              ),
            ),
          );
        },
        onLikeChanged: (newLiked, newLikes) async {
          try {
            final userId = _authProvider.userId;
            if (userId == null) {
              print('❌ SearchFeedScreen: User not authenticated for like');
              return;
            }
            
            print('🔍 SearchFeedScreen: Toggling like for post: ${posts[index]['id']}, isLiked: $newLiked');
            final result = await _backendService.togglePostLike(posts[index]['id'], userId, !newLiked);
            print('✅ SearchFeedScreen: Like toggled successfully, result: $result');
            
            setState(() {
              _likedPosts[index] = newLiked;
              _likeCounts[index] = newLikes;
            });
            
            HapticFeedback.lightImpact();
          } catch (e) {
            print('❌ SearchFeedScreen: Failed to toggle like: $e');
            // Show error message to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update like: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onShare: () {
          final text =
              "$username shared a song: ${post['track']} by ${post['artist']}";
          Share.share(text);
        },
        onFollowPressed: () {},
      ),
    );
  }

  void _cancelSearch() {
    setState(() {
      query = '';
      _controller.clear();
      _isSearching = false;
      _searchFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar + cancel button
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      focusNode: _searchFocusNode,
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (query.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    query = '';
                                    _controller.clear();
                                    _isSearching = true;
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: Colors.white70),
                              onPressed: _listen,
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onTap: () => setState(() => _isSearching = true),
                      onSubmitted: (_) =>
                          setState(() => _isSearching = true),
                    ),
                  ),
                ),
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: _cancelSearch,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),

            // Suggestions or discovery feed
            if (_isSearching)
              _buildSuggestionDropdown()
            else
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('Random Discovery',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      );
                    }
                    final post = posts[index - 1];
                    return _buildMusicPost(post, index - 1);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

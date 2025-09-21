import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:songbuddy/screens/user_profile_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchFeedScreen extends StatefulWidget {
  const SearchFeedScreen({super.key});

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen> {
  String query = '';
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _searchFocusNode;

  // Speech recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChange);

    _controller.addListener(() {
      final t = _controller.text;
      if (t != query) {
        setState(() {
          query = t;
          _isSearching = _searchFocusNode.hasFocus || query.trim().isNotEmpty;
        });
      }
    });
  }

  void _onFocusChange() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _isSearching = true;
      } else {
        _isSearching = query.trim().isNotEmpty;
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
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

      setState(() {
        _isListening = true;
        _isSearching = true;
      });

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

  // Mock data
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
    },
    {
      'track': 'Blinding Lights',
      'artist': 'The Weeknd',
      'user': 'Bob',
      'desc': 'Still one of my favorites!',
      'coverUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s',
    },
    {
      'track': 'Sunflower',
      'artist': 'Post Malone',
      'user': 'Charlie',
      'desc': 'Always lifts my mood.',
      'coverUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF0Jqpe95kORYuGnJhSprCr8KG_WtwW8oS9Q&ss',
    },
  ];

  List<Map<String, dynamic>> get filteredUsers {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return users
        .where((u) => (u['username'] as String).toLowerCase().startsWith(q))
        .toList();
  }

  Widget _buildMusicPost(Map<String, dynamic> post) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              post['coverUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.white12),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.36)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    post['coverUrl'],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.white12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['track'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(post['artist'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
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

  Widget _buildSuggestionDropdown() {
    if (!_isSearching || query.trim().isEmpty) return const SizedBox.shrink();

    final suggestions = filteredUsers;
    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text("No users found",
              style: TextStyle(color: Colors.white54)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              query = '';
                              _controller.clear();
                              _isSearching = false;
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
                    setState(() => _isSearching = query.trim().isNotEmpty),
              ),
            ),

            // If searching → dropdown list; else → discovery posts
            if (_isSearching && query.trim().isNotEmpty)
              _buildSuggestionDropdown()
            else
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    const Text('Random Discovery',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...posts.map((p) => _buildMusicPost(p)).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

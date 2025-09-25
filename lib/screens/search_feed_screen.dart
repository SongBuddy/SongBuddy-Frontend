import 'dart:async';
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
  bool _isLoadingUsers = false;
  String? _searchError;

  // Backend services
  late final BackendService _backendService;
  late final AuthProvider _authProvider;

  // Search debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  // Real search results
  List<Map<String, dynamic>> _searchResults = [];

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
          _searchError = null;
        });
        _performSearch(t);
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
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _controller.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  /// Perform debounced search
  void _performSearch(String searchQuery) {
    _debounceTimer?.cancel();
    
    if (searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingUsers = false;
        _searchError = null;
      });
      _onSearchComplete();
      return;
    }

    if (searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingUsers = false;
        _searchError = null;
      });
      return;
    }

    _debounceTimer = Timer(_debounceDelay, () {
      _searchUsers(searchQuery.trim());
    });
  }

  /// Search users from backend
  Future<void> _searchUsers(String searchQuery) async {
    if (!mounted) return;

    setState(() {
      _isLoadingUsers = true;
      _searchError = null;
    });

    try {
      print('🔍 SearchFeedScreen: Searching users with query: "$searchQuery"');
      final results = await _backendService.searchUsers(searchQuery, limit: 20);
      
      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isLoadingUsers = false;
        _searchError = null;
      });

      print('✅ SearchFeedScreen: Found ${results.length} users');
      _onSearchComplete();
    } catch (e) {
      if (!mounted) return;

      print('❌ SearchFeedScreen: Search error: $e');
      setState(() {
        _searchResults = [];
        _isLoadingUsers = false;
        _searchError = 'Failed to search users: ${e.toString()}';
      });
      _onSearchComplete();
    }
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

  // Removed hardcoded users - now using real backend search

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

  // Removed filteredUsers getter - now using _searchResults from backend

  Widget _buildSuggestionDropdown() {
    // Show loading state
    if (_isLoadingUsers) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white70),
              SizedBox(height: 16),
              Text("Searching users...", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_searchError != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                _searchError!,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show no results
    if (_searchResults.isEmpty && query.trim().isNotEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text("No users found", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    // Show search results
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
        itemBuilder: (context, idx) {
          final user = _searchResults[idx];
          final displayName = user['displayName'] as String? ?? 'Unknown User';
          final username = user['username'] as String? ?? '';
          final followersCount = user['followersCount'] as int? ?? 0;
          final profilePicture = user['profilePicture'] as String? ?? '';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              backgroundImage: profilePicture.isNotEmpty 
                  ? NetworkImage(profilePicture) 
                  : null,
              child: profilePicture.isEmpty 
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                Text(
                  '$followersCount followers',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            onTap: () {
              _searchFocusNode.unfocus();
              // Clear search after selecting a user to go back to discovery feed
              setState(() {
                _isSearching = false;
                query = '';
                _controller.clear();
                _searchResults = [];
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    username: displayName,
                    avatarUrl: profilePicture.isNotEmpty 
                        ? profilePicture 
                        : "https://i.pravatar.cc/150?img=1",
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
    _debounceTimer?.cancel();
    setState(() {
      query = '';
      _controller.clear();
      _isSearching = false;
      _searchResults = [];
      _isLoadingUsers = false;
      _searchError = null;
      _searchFocusNode.unfocus();
    });
  }

  void _onSearchComplete() {
    // Only set _isSearching to false if the search field is empty
    // This allows users to see search results while keeping the search active
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
      });
    }
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
                                    _searchResults = [];
                                    _isLoadingUsers = false;
                                    _searchError = null;
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

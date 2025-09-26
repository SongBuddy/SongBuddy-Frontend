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

  // Discovery posts from backend
  List<Map<String, dynamic>> _discoveryPosts = [];
  bool _isLoadingDiscovery = false;
  String? _discoveryError;

  // Track likes for posts
  final Map<String, bool> _likedPosts = {}; // Changed to String key (post ID)
  final Map<String, int> _likeCounts = {}; // Changed to String key (post ID)

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

    // Load discovery posts from backend
    _loadDiscoveryPosts();
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

  // Removed hardcoded posts - now using dynamic discovery feed from backend

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

  /// Build discovery post widget (similar to music post but for discovery posts)
  Widget _buildDiscoveryPost(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    final username = post['username'] as String? ?? 'Unknown User';
    final userAvatar = post['userAvatar'] as String? ?? 'https://i.pravatar.cc/150?img=1';
    final songName = post['songName'] as String? ?? 'Unknown Track';
    final artistName = post['artistName'] as String? ?? 'Unknown Artist';
    final songImage = post['songImage'] as String? ?? '';
    final description = post['description'] as String? ?? '';
    final createdAt = post['createdAt'] as String? ?? '';
    
    // Calculate time since posted
    String timeAgo = 'now';
    if (createdAt.isNotEmpty) {
      try {
        final postTime = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(postTime);
        
        if (difference.inHours < 1) {
          timeAgo = '${difference.inMinutes}m';
        } else if (difference.inDays < 1) {
          timeAgo = '${difference.inHours}h';
        } else {
          timeAgo = '${difference.inDays}d';
        }
      } catch (e) {
        timeAgo = 'now';
      }
    }

    final initialLikes = _likeCounts[postId] ?? 0;
    final isInitiallyLiked = _likedPosts[postId] ?? false;
    
    print('🎵 Building discovery post $postId: initialLikes=$initialLikes, isInitiallyLiked=$isInitiallyLiked');
    
    return MusicPostCard(
      username: username,
      avatarUrl: userAvatar,
      trackTitle: songName,
      artist: artistName,
      coverUrl: songImage,
      timeAgo: timeAgo,
      description: description,
      initialLikes: initialLikes,
      isInitiallyLiked: isInitiallyLiked,
      onLikeChanged: (newLiked, newLikes) async {
        try {
          final userId = _authProvider.userId;
          if (userId == null) {
            print('❌ SearchFeedScreen: User not authenticated for like');
            return;
          }
          
          print('🔍 SearchFeedScreen: Toggling like for discovery post: $postId, isLiked: $newLiked');
          final result = await _backendService.togglePostLike(postId, userId, !newLiked);
          print('✅ SearchFeedScreen: Like toggled successfully, result: $result');
          
          setState(() {
            _likedPosts[postId] = newLiked;
            _likeCounts[postId] = newLikes;
          });
          
          HapticFeedback.lightImpact();
        } catch (e) {
          print('❌ SearchFeedScreen: Failed to toggle like: $e');
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
        final text = "$username shared a song: $songName by $artistName";
        Share.share(text);
      },
      onFollowPressed: () {
        // TODO: Implement follow functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Follow $username'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildMusicPost(Map<String, dynamic> post, int index) {
    final username = post['user'] as String;
    final postId = post['id'] as String? ?? 'post-$index';
    final likeCount = _likeCounts[postId] ?? 0;
    final isLiked = _likedPosts[postId] ?? false;

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
            
            print('🔍 SearchFeedScreen: Toggling like for post: $postId, isLiked: $newLiked');
            final result = await _backendService.togglePostLike(postId, userId, !newLiked);
            print('✅ SearchFeedScreen: Like toggled successfully, result: $result');
            
            setState(() {
              _likedPosts[postId] = newLiked;
              _likeCounts[postId] = newLikes;
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

  /// Load discovery posts from backend
  Future<void> _loadDiscoveryPosts() async {
    setState(() {
      _isLoadingDiscovery = true;
      _discoveryError = null;
    });

    try {
      final userId = _authProvider.userId;
      final posts = await _backendService.getDiscoveryPosts(userId: userId);
      
      setState(() {
        _discoveryPosts = posts;
        _isLoadingDiscovery = false;
        
        // Initialize like counts for discovery posts
        for (final post in posts) {
          final postId = post['id'] as String;
          final likesCount = post['likesCount'] as int? ?? 0;
          final isLiked = post['isLiked'] as bool? ?? false;
          
          print('🔍 Discovery Post $postId: likesCount=$likesCount, isLiked=$isLiked');
          
          _likedPosts[postId] = isLiked;
          _likeCounts[postId] = likesCount;
        }
      });
      
      print('✅ SearchFeedScreen: Loaded ${posts.length} discovery posts');
    } catch (e) {
      setState(() {
        _discoveryError = e.toString();
        _isLoadingDiscovery = false;
      });
      print('❌ SearchFeedScreen: Failed to load discovery posts: $e');
    }
  }

  /// Build the discovery feed UI
  Widget _buildDiscoveryFeed() {
    if (_isLoadingDiscovery) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white70),
              SizedBox(height: 16),
              Text("Loading discovery posts...", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (_discoveryError != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                _discoveryError!,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDiscoveryPosts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_discoveryPosts.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_off, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text("No discovery posts available", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadDiscoveryPosts,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _discoveryPosts.length,
          itemBuilder: (context, index) {
            final post = _discoveryPosts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildDiscoveryPost(post),
              ),
            );
          },
        ),
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
              _buildDiscoveryFeed(),
          ],
        ),
      ),
    );
  }
}

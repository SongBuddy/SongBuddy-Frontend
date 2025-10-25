import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/Post.dart';
import '../services/backend_service.dart';
import '../providers/auth_provider.dart';
import '../services/spotify_service.dart';
import '../utils/error_snackbar_utils.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic> selectedTrack;
  final String selectedTrackId;

  const CreatePostScreen({
    super.key,
    required this.selectedTrack,
    required this.selectedTrackId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with TickerProviderStateMixin {
  late final TextEditingController _descriptionController;
  late final AuthProvider _authProvider;
  late final BackendService _backendService;
  late final SpotifyService _spotifyService;

  bool _isPosting = false;
  final int _maxDescriptionLength = 280;

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _heroBannerController;
  late AnimationController _successAnimationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _heroBannerScaleAnimation;
  late Animation<double> _heroBannerGlowAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _authProvider = AuthProvider();
    _backendService = BackendService();
    _spotifyService = SpotifyService();

    // Initialize animations
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _heroBannerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _heroBannerScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroBannerController,
        curve: Curves.elasticOut,
      ),
    );

    _heroBannerGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroBannerController,
        curve: Curves.easeInOut,
      ),
    );

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _successOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start hero banner animation
    _heroBannerController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _backgroundAnimationController.dispose();
    _heroBannerController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    print('🚀 ===== STARTING POST CREATION =====');
    print('🔍 CreatePost: User authenticated: ${_authProvider.isAuthenticated}');
    print('🔍 CreatePost: Access token available: ${_authProvider.accessToken != null}');
    print('🔍 CreatePost: Selected track: ${widget.selectedTrack['name']}');
    print('🔍 CreatePost: Description length: ${_descriptionController.text.length}');
    
    // Check if user is authenticated
    if (!_authProvider.isAuthenticated) {
      _showSnackBar('Please log in to create a post', Colors.orange);
      return;
    }
    
    if (_authProvider.accessToken == null) {
      _showSnackBar('Access token not found. Please log in again.', Colors.orange);
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // Fetch current user data from Spotify API
      print('🔍 CreatePost: Fetching user data from Spotify API...');
      final userData = await _spotifyService.getCurrentUser(_authProvider.accessToken!);
      
      // Extract user information from Spotify API response
      final userId = userData['id'] as String? ?? '';
      final displayName = userData['display_name'] as String? ?? '';
      final profilePicture = (userData['images'] as List<dynamic>?)?.isNotEmpty == true
          ? userData['images'][0]['url'] as String
          : '';
      
      print('🔍 CreatePost: Spotify User ID: $userId');
      print('🔍 CreatePost: Spotify Display Name: $displayName');
      print('🔍 CreatePost: Spotify Profile Picture: $profilePicture');
      
      // Ensure we have a valid username
      final finalUsername = displayName.trim().isNotEmpty ? displayName.trim() : 'Spotify User';
      print('🔍 CreatePost: Final username: $finalUsername');
      
      Post post;
      try {
        post = Post(
          id: '', // Will be generated by backend
          userId: userId,
          username: finalUsername,
          userProfilePicture: profilePicture,
          songName: widget.selectedTrack['name'] ?? 'Unknown Song',
          artistName: (widget.selectedTrack['artists'] as List<dynamic>?)
              ?.map((artist) => artist['name'] as String)
              .join(', ') ?? 'Unknown Artist',
          songImage: (widget.selectedTrack['album']?['images'] as List<dynamic>?)
              ?.isNotEmpty == true
              ? widget.selectedTrack['album']['images'][0]['url'] as String
              : '',
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          likeCount: 0,
          createdAt: DateTime.now(),
          timeline: 'now',
          isLikedByCurrentUser: false,
        );
        print('✅ CreatePost: Post object created successfully');
      } catch (e) {
        print('❌ CreatePost: Error creating Post object: $e');
        throw Exception('Failed to create post object: $e');
      }
      
      // Debug: Print individual fields before creating Post
      print('🔍 CreatePost: userId: "$userId"');
      print('🔍 CreatePost: username: "$finalUsername"');
      print('🔍 CreatePost: userProfilePicture: "$profilePicture"');
      print('🔍 CreatePost: songName: "${widget.selectedTrack['name'] ?? 'NULL'}"');
      print('🔍 CreatePost: artistName: "${(widget.selectedTrack['artists'] as List<dynamic>?)?.map((artist) => artist['name'] as String).join(', ') ?? 'NULL'}"');
      print('🔍 CreatePost: songImage: "${(widget.selectedTrack['album']?['images'] as List<dynamic>?)?.isNotEmpty == true ? widget.selectedTrack['album']['images'][0]['url'] as String : 'NULL'}"');
      
      // Debug: Print the post data being sent
      print('🔍 CreatePost: Post data: ${post.toJson()}');
      
      // Comprehensive logging of all post information
      print('📝 ===== POST CREATION SUMMARY =====');
      print('👤 USER INFORMATION:');
      print('   • User ID: $userId');
      print('   • Username: $finalUsername');
      print('   • Profile Picture: $profilePicture');
      print('🎵 SONG INFORMATION:');
      print('   • Song Name: ${widget.selectedTrack['name'] ?? 'Unknown Song'}');
      print('   • Artist Name: ${(widget.selectedTrack['artists'] as List<dynamic>?)?.map((artist) => artist['name'] as String).join(', ') ?? 'Unknown Artist'}');
      print('   • Song Image: ${(widget.selectedTrack['album']?['images'] as List<dynamic>?)?.isNotEmpty == true ? widget.selectedTrack['album']['images'][0]['url'] as String : 'No Image'}');
      print('📝 POST CONTENT:');
      print('   • Description: ${_descriptionController.text.trim().isEmpty ? 'No description' : _descriptionController.text.trim()}');
      print('   • Like Count: 0');
      print('   • Created At: ${DateTime.now()}');
      print('   • Timeline: now');
      print('📤 SENDING TO BACKEND:');
      print('   • URL: http://192.168.227.108:3000/api/posts/create');
      print('   • JSON: ${jsonEncode(post.toJson())}');
      print('=====================================');

      await _backendService.createPost(post);

      if (mounted) {
        // Show success animation
        await _successAnimationController.forward();

        ErrorSnackbarUtils.showSuccessSnackbar(context, 'Post created successfully!');

        // Delay to show success animation
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'create_post');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.selectedTrack;
    final albumImages = track['album']?['images'] as List<dynamic>? ?? [];
    final trackImage = albumImages.isNotEmpty
        ? albumImages.first['url'] as String
        : '';
    final artists = track['artists'] as List<dynamic>? ?? [];
    final artistNames = artists.map((artist) => artist['name'] as String).join(', ');
    final trackName = track['name'] ?? 'Unknown Track';

    return Scaffold(
      backgroundColor: AppColors.darkBackgroundStart, // App theme dark background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Minimal top bar
              _buildMinimalTopBar(),

              // Main content - Scrollable when keyboard appears
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Square album artwork
                        _buildSquareAlbumArt(trackImage),

                        const SizedBox(height: 16),

                        // Track name (compact)
                        Text(
                          trackName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onDarkPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Artist name (compact)
                        Text(
                          artistNames,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onDarkSecondary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 20),

                        // "Share Your Thoughts" label
                        Text(
                          'Share Your Thoughts',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onDarkPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Text input field (compact)
                        _buildMinimalTextField(),

                        const SizedBox(height: 12),

                        // Character counter
                        _buildMinimalCharacterCounter(),

                        const SizedBox(height: 32),

                        // Create Post button at bottom
                        _buildCreatePostButton(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button with glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.onDarkPrimary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // Title
          Text(
            'Create Post',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onDarkPrimary,
              letterSpacing: -0.3,
            ),
          ),

          // Placeholder for symmetry
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Widget _buildSquareAlbumArt(String trackImage) {
    return Center(
      child: AnimatedBuilder(
        animation: _heroBannerController,
        builder: (context, child) {
          return Transform.scale(
            scale: _heroBannerScaleAnimation.value,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentMint.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: trackImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: trackImage,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        memCacheHeight: 600,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.darkBackgroundEnd,
                          child: const Icon(
                            Icons.music_note_rounded,
                            size: 80,
                            color: AppColors.accentMint,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.darkBackgroundEnd,
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: AppColors.accentMint,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinimalTextField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            minLines: 3,
            maxLength: _maxDescriptionLength,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              letterSpacing: -0.3,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'What do you think about this track?',
              hintStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black38,
                letterSpacing: -0.3,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: '',
            ),
            cursorColor: AppColors.primary,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalCharacterCounter() {
    final currentLength = _descriptionController.text.length;
    final percentage = currentLength / _maxDescriptionLength;

    Color getColor() {
      if (percentage < 0.8) return AppColors.onDarkSecondary;
      if (percentage < 0.9) return AppColors.warning;
      return AppColors.error;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$currentLength / $_maxDescriptionLength characters',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: getColor(),
            letterSpacing: -0.2,
          ),
        ),
        if (currentLength > 0)
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: getColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreatePostButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary, // Purple color matching profile FAB
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isPosting ? null : _createPost,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: _isPosting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Create Post',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Modern back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onDarkPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.accentMint, AppColors.accentGreen],
                  ).createShader(bounds),
                  child: Text(
                    'Create Post',
                    style: AppTextStyles.heading2OnDark.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Post button with shimmer effect
                if (_isPosting)
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentMint),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentMint, AppColors.accentGreen],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentMint.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _createPost,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(
                            'Post',
                            style: AppTextStyles.bodyOnDark.copyWith(
                              color: AppColors.darkBackgroundStart,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeroBanner(String trackImage, Map<String, dynamic> track, String artistNames) {
    return AnimatedBuilder(
      animation: _heroBannerController,
      builder: (context, child) {
        return Transform.scale(
          scale: _heroBannerScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMint.withOpacity(0.2 * _heroBannerGlowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 1.5,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated gradient overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _backgroundAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accentMint.withOpacity(0.05 * _backgroundAnimation.value),
                                    AppColors.accentGreen.withOpacity(0.05 * (1 - _backgroundAnimation.value)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Album cover with glow effect
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentMint.withOpacity(0.3 * _heroBannerGlowAnimation.value),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: trackImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: trackImage,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 200,
                                        memCacheHeight: 200,
                                        errorWidget: (context, url, error) => _buildPlaceholderImage(),
                                      )
                                    : _buildPlaceholderImage(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Track info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    track['name'] ?? 'Unknown Song',
                                    style: AppTextStyles.heading2OnDark.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentMint,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accentMint.withOpacity(0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          artistNames,
                                          style: AppTextStyles.captionOnDark.copyWith(
                                            color: AppColors.onDarkSecondary,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedInputCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Minimal iOS-style input card with ultra-smooth glassmorphism
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  width: 0.5,
                  color: Colors.white.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.accentMint.withOpacity(0.06),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // iOS-style input with smooth animations
                  _CupertinoComposerInput(
                    controller: _descriptionController,
                    maxLength: _maxDescriptionLength,
                    onChanged: (_) => setState(() {}),
                  ),

                  // Subtle divider
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 0.5,
                    color: Colors.black.withOpacity(0.06),
                  ),

                  // Minimal iOS-style character counter
                  _buildCupertinoCharacterCount(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCupertinoCharacterCount() {
    final currentLength = _descriptionController.text.length;
    final percentage = currentLength / _maxDescriptionLength;

    Color getColor() {
      if (percentage < 0.8) return const Color(0xFF8E8E93); // iOS gray
      if (percentage < 0.9) return const Color(0xFFFF9500); // iOS orange
      return const Color(0xFFFF3B30); // iOS red
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimal character count
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: TextStyle(
              color: getColor(),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.08,
            ),
            child: Text('$currentLength / $_maxDescriptionLength'),
          ),

          // Minimal progress indicator
          if (currentLength > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.black.withOpacity(0.06),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: getColor(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCharacterCount() {
    final currentLength = _descriptionController.text.length;
    final remaining = _maxDescriptionLength - currentLength;
    final percentage = currentLength / _maxDescriptionLength;

    Color getColor() {
      if (percentage < 0.7) return AppColors.accentMint;
      if (percentage < 0.85) return Colors.yellow;
      if (percentage < 0.95) return Colors.orange;
      return Colors.red;
    }

    return Row(
      children: [
        // Animated progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(getColor()),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Character count with animated color
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: AppTextStyles.captionOnDark.copyWith(
            color: getColor(),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          child: Text('$currentLength / $_maxDescriptionLength'),
        ),
      ],
    );
  }

  Widget _buildSelectedTrackCard(Map<String, dynamic> track, String trackImage, String artistNames) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Track image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: trackImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: trackImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      errorWidget: (context, url, error) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            
            const SizedBox(width: 16),
            
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['name'] ?? 'Unknown Song',
                    style: AppTextStyles.bodyOnDark.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
                    style: AppTextStyles.captionOnDark.copyWith(
                      color: AppColors.onDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Check icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Removed old TextField-based input; using custom input below

  Widget _buildCharacterCount() {
    final currentLength = _descriptionController.text.length;
    final remaining = _maxDescriptionLength - currentLength;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$currentLength/$_maxDescriptionLength',
          style: AppTextStyles.captionOnDark.copyWith(
            color: remaining < 20 
                ? Colors.orange 
                : AppColors.onDarkSecondary.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(String trackImage, Map<String, dynamic> track, String artistNames) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background cover (blurred fallback)
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.onDarkPrimary.withOpacity(0.10),
                  AppColors.onDarkPrimary.withOpacity(0.04),
                ],
              ),
              border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.08)),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                // Cover
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: trackImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: trackImage,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            memCacheHeight: 240,
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Texts
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          track['name'] ?? 'Unknown Song',
                          style: AppTextStyles.heading2OnDark.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artistNames,
                          style: AppTextStyles.captionOnDark.copyWith(color: AppColors.onDarkSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const _ComposerGlass({required this.child, this.borderRadius = 12});

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
            border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CupertinoComposerInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String>? onChanged;
  const _CupertinoComposerInput({required this.controller, required this.maxLength, this.onChanged});

  @override
  State<_CupertinoComposerInput> createState() => _CupertinoComposerInputState();
}

class _CupertinoComposerInputState extends State<_CupertinoComposerInput> {
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 16,
          height: 1.4,
          letterSpacing: -0.3,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 4,
        minLines: 3,
        maxLength: widget.maxLength,
        decoration: InputDecoration(
          hintText: 'Share your thoughts...',
          hintStyle: TextStyle(
            color: const Color(0xFF3C3C43).withOpacity(0.3),
            fontSize: 16,
            height: 1.4,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
          isDense: true,
        ),
        cursorColor: AppColors.accentMint,
        cursorWidth: 2,
        cursorRadius: const Radius.circular(1),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: widget.onChanged,
      ),
    );
  }
}

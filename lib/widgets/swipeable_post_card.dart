import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/widgets/music_post_card.dart';

class SwipeablePostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Function(String)? onEditDescription;
  final void Function(bool isLiked, int likes)? onLikeChanged;
  final VoidCallback? onCardTap;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInSpotify;
  final VoidCallback? onUserTap;
  final bool showUserInfo;

  const SwipeablePostCard({
    super.key,
    required this.post,
    this.onDelete,
    this.onEdit,
    this.onEditDescription,
    this.onLikeChanged,
    this.onCardTap,
    this.onShare,
    this.onOpenInSpotify,
    this.onUserTap,
    this.showUserInfo = true,
  });

  @override
  State<SwipeablePostCard> createState() => _SwipeablePostCardState();
}

class _SwipeablePostCardState extends State<SwipeablePostCard>
    with TickerProviderStateMixin {
  late AnimationController _resetController;
  
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _hasTriggeredAction = false;
  
  // Performance optimizations
  static const double _maxDragDistance = 250.0;
  static const double _triggerThreshold = 100.0;
  static const double _hapticThreshold = 80.0;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster reset
      vsync: this,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _hasTriggeredAction = false;
    _hasTriggeredHaptic = false;
    _resetController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _hasTriggeredAction) return;
    
    // Optimize: Only update if significant movement
    final newOffset = (_dragOffset + details.delta.dx).clamp(-_maxDragDistance, _maxDragDistance);
    
    if ((newOffset - _dragOffset).abs() < 2.0) return; // Skip micro-movements
    
    _dragOffset = newOffset;
    
    // Haptic feedback at threshold (only once per swipe)
    if (!_hasTriggeredHaptic && _dragOffset.abs() > _hapticThreshold) {
      _hasTriggeredHaptic = true;
      HapticFeedback.selectionClick();
    }
    
    // Only rebuild when necessary
    if (mounted) {
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    _isDragging = false;
    
    // Check if threshold was reached and actions are available
    if (_dragOffset.abs() > _triggerThreshold && !_hasTriggeredAction) {
      _hasTriggeredAction = true;
      
      if (_dragOffset < 0 && widget.onDelete != null) {
        // Swipe left - Delete (only if delete is available)
        HapticFeedback.mediumImpact();
        _showDeleteConfirmation();
      } else if (_dragOffset > 0 && widget.onEditDescription != null) {
        // Swipe right - Edit (only if edit is available)
        HapticFeedback.lightImpact();
        _showEditOptions();
      } else {
        // No action available, reset position
        _resetPosition();
      }
    } else {
      // Reset position smoothly
      _resetPosition();
    }
  }

  void _resetPosition() {
    if (_dragOffset == 0.0) return;
    
    // Simple and reliable reset using AnimatedBuilder pattern
    _resetController.reset();
    _resetController.forward().then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _hasTriggeredAction = false;
          _hasTriggeredHaptic = false;
        });
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.onDarkPrimary.withOpacity(0.9),
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPosition();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
              _resetPosition();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOptions() {
    showDialog(
      context: context,
      builder: (context) => _EditPostDialog(
        post: widget.post,
        onEdit: (newDescription) {
          // Pass the new description to the parent widget
          widget.onEditDescription?.call(newDescription);
          _resetPosition();
        },
        onCancel: () {
          // Reset position when dialog is cancelled
          _resetPosition();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _resetController,
      builder: (context, child) {
        // Calculate current offset (either from drag or reset animation)
        final currentOffset = _isDragging 
            ? _dragOffset 
            : _dragOffset * (1.0 - _resetController.value);
        
        // Calculate opacity based on drag distance for smooth visual feedback
        final dragProgress = (currentOffset.abs() / _triggerThreshold).clamp(0.0, 1.0);
        final backgroundOpacity = (dragProgress * 0.9).clamp(0.0, 0.9);
        
        return Stack(
          children: [
            // Optimized background indicators - only show when dragging and action is available
            if (currentOffset < -10 && widget.onDelete != null) // Swipe left - Delete indicator (only if delete is available)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(backgroundOpacity),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Opacity(
                        opacity: dragProgress,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'DELETE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            
            if (currentOffset > 10 && widget.onEditDescription != null) // Swipe right - Edit indicator (only if edit is available)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(backgroundOpacity),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 16),
                      Opacity(
                        opacity: dragProgress,
                        child: const Row(
                          children: [
                            Text(
                              'EDIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main post card with conditional swipe gestures
            GestureDetector(
              // Only enable pan gestures if delete or edit actions are available
              onPanStart: (widget.onDelete != null || widget.onEditDescription != null) ? _onPanStart : null,
              onPanUpdate: (widget.onDelete != null || widget.onEditDescription != null) ? _onPanUpdate : null,
              onPanEnd: (widget.onDelete != null || widget.onEditDescription != null) ? _onPanEnd : null,
              child: Transform.translate(
                offset: Offset(currentOffset, 0),
                child: MusicPostCard(
                  username: widget.showUserInfo ? widget.post.username : '',
                  avatarUrl: widget.showUserInfo ? widget.post.userProfilePicture : '',
                  trackTitle: widget.post.songName,
                  artist: widget.post.artistName,
                  coverUrl: widget.post.songImage,
                  timeAgo: widget.post.timeline,
                  description: widget.post.description,
                  initialLikes: widget.post.likeCount,
                  isInitiallyLiked: widget.post.isLikedByCurrentUser,
                  onLikeChanged: widget.onLikeChanged,
                  onCardTap: widget.onCardTap,
                  onShare: widget.onShare,
                  onOpenInSpotify: widget.onOpenInSpotify,
                  onUserTap: widget.onUserTap,
                  showFollowButton: false,
                  showUserInfo: widget.showUserInfo,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EditPostDialog extends StatefulWidget {
  final Post post;
  final Function(String) onEdit;
  final VoidCallback? onCancel;

  const _EditPostDialog({
    required this.post,
    required this.onEdit,
    this.onCancel,
  });

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late TextEditingController _descriptionController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.post.description ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.onDarkPrimary.withOpacity(0.9),
      title: const Text(
        'Edit Post',
        style: TextStyle(color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit your post description:',
            style: TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 280,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this song...',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () {
            Navigator.pop(context);
            widget.onCancel?.call();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isUpdating ? null : _updatePost,
          child: _isUpdating 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Update',
                style: TextStyle(color: Colors.green),
              ),
        ),
      ],
    );
  }

  Future<void> _updatePost() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Call the onEdit callback with the new description
      widget.onEdit(_descriptionController.text.trim());
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}
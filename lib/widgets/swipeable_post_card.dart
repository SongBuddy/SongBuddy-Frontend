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
    this.showUserInfo = true,
  });

  @override
  State<SwipeablePostCard> createState() => _SwipeablePostCardState();
}

class _SwipeablePostCardState extends State<SwipeablePostCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _hasTriggeredAction = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _hasTriggeredAction = false;
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-300.0, 300.0);
      
      // Auto-trigger when swiped far enough
      const double triggerThreshold = 120.0;
      
      if (!_hasTriggeredAction) {
        if (_dragOffset < -triggerThreshold) {
          // Swipe left - Auto trigger delete
          _hasTriggeredAction = true;
          HapticFeedback.mediumImpact();
          _showDeleteConfirmation();
        } else if (_dragOffset > triggerThreshold) {
          // Swipe right - Auto trigger edit
          _hasTriggeredAction = true;
          HapticFeedback.lightImpact();
          _showEditOptions();
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    _isDragging = false;
    
    // Reset position if no action was triggered
    if (!_hasTriggeredAction) {
      _resetPosition();
    }
  }

  void _resetPosition() {
    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = 0.0;
        _hasTriggeredAction = false;
      });
      _animationController.reset();
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
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background indicators
            if (_dragOffset < 0) // Swipe left - Delete indicator
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'DELETE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
              ),
            
            if (_dragOffset > 0) // Swipe right - Edit indicator
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 20),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main post card with transform
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
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
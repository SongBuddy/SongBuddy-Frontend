import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_colors.dart';

/// Shimmer effect widget for loading states
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
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
                AppColors.onDarkPrimary.withOpacity(0.12),
                AppColors.onDarkPrimary.withOpacity(0.05),
                AppColors.onDarkPrimary.withOpacity(0.12),
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

/// Shimmer skeleton box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Shimmer skeleton circle
class ShimmerCircle extends StatelessWidget {
  final double diameter;

  const ShimmerCircle({
    super.key,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer post card that mimics the MusicPostCard layout
class ShimmerPostCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerPostCard({
    super.key,
    this.height = 180,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.onDarkPrimary.withOpacity(0.03),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Background shimmer
            Positioned.fill(
              child: Shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.onDarkPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ),

            // Content
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + username (no time shimmer)
                  Row(
                    children: [
                      ShimmerCircle(diameter: 28),
                      SizedBox(width: 12),
                      ShimmerBox(width: 60, height: 13, radius: 6),
                      // No time shimmer - just empty space
                      SizedBox(width: 30),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Middle: cover + song info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 60, radius: 12),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 150, height: 16, radius: 8),
                            SizedBox(height: 6),
                            ShimmerBox(width: 100, height: 13, radius: 6),
                            SizedBox(height: 8),
                            ShimmerBox(width: 180, height: 12, radius: 6),
                            SizedBox(height: 4),
                            ShimmerBox(width: 120, height: 12, radius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),

                  // Bottom: 3 circles for action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShimmerCircle(diameter: 18),
                      SizedBox(width: 12),
                      ShimmerCircle(diameter: 18),
                      SizedBox(width: 12),
                      ShimmerCircle(diameter: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer list for multiple post cards
class ShimmerPostList extends StatelessWidget {
  final int itemCount;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;

  const ShimmerPostList({
    super.key,
    this.itemCount = 3,
    this.height = 180,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: ShimmerPostCard(
            height: height,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

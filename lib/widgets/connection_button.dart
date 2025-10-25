// lib/widgets/connection_button.dart
import 'package:flutter/material.dart';

typedef ConnectionAction = Future<bool> Function();

class ConnectionButton extends StatefulWidget {
  final String label;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ConnectionAction onPressed;
  final double minWidth;

  const ConnectionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.minWidth = 160,
  });

  @override
  State<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<ConnectionButton>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _success = false;
  String? _errorMessage;
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    setState(() {
      _loading = true;
      _success = false;
      _errorMessage = null;
    });

    try {
      final result = await widget.onPressed();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = result;
      });
      if (result) {
        // show success animation briefly
        _iconController.forward();
        await Future.delayed(const Duration(milliseconds: 700));
        _iconController.reverse();
      } else {
        setState(() {
          _errorMessage = 'Action failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg =
        widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
          onPressed: _loading ? null : _handleTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _loading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Please wait', style: TextStyle(color: fg)),
                    ],
                  )
                : _success
                    ? Row(
                        key: const ValueKey('success'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                CurvedAnimation(
                                    parent: _iconController,
                                    curve: Curves.elasticOut)),
                            child: const Icon(Icons.check_circle_outline,
                                size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Connected', style: TextStyle(color: fg)),
                        ],
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leading != null) ...[
                            widget.leading!,
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                              child: Text(widget.label,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

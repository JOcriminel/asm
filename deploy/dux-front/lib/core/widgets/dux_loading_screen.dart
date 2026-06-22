import 'dart:async';
import 'package:flutter/material.dart';

class DuxLoadingScreen extends StatefulWidget {
  final bool isFullScreen;

  const DuxLoadingScreen({
    super.key,
    this.isFullScreen = true,
  });

  @override
  State<DuxLoadingScreen> createState() => _DuxLoadingScreenState();
}

class _DuxLoadingScreenState extends State<DuxLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  int _dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Timer to cycle the dots
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Background and text colors matching the DUX theme
    final backgroundColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF7F8FA);
    final textColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Breathing DUX Logo
          FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Loading Text with Animated Dots
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'loading',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              // Dots placeholder to prevent text width jumping during animation
              SizedBox(
                width: 24,
                child: Text(
                  '.' * _dotCount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Modern micro linear progress bar indicator
          SizedBox(
            width: 100,
            height: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF4A7FC4) : const Color(0xFF2196F3),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: content,
      );
    } else {
      return Container(
        color: backgroundColor,
        child: content,
      );
    }
  }
}

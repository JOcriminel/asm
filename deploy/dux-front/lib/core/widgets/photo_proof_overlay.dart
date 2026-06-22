import 'dart:async';
import 'package:flutter/material.dart';

class PhotoProofOverlay extends StatefulWidget {
  const PhotoProofOverlay({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const PhotoProofOverlay(),
      ),
    );
  }

  @override
  State<PhotoProofOverlay> createState() => _PhotoProofOverlayState();
}

class _PhotoProofOverlayState extends State<PhotoProofOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  bool _isShutterFlashing = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _triggerCapture() {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _isShutterFlashing = true;
    });

    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isShutterFlashing = false;
        });
      }
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        // Return a mock base64 image representation
        Navigator.of(context).pop("MOCK_PHOTO_PROOF_BASE64_DATA_STRING");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mock Camera Viewfinder Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_search_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Viseur Appareil Photo (Simulé)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Rule of Thirds Grid Lines (Subtle)
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.08), width: 1),
                const Spacer(),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.08), width: 1),
                const Spacer(),
              ],
            ),
          ),
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const Spacer(),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const Spacer(),
              ],
            ),
          ),

          // 3. Scanning Cutout Framing Overlay
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final cutoutWidth = width * 0.85;
                final cutoutHeight = height * 0.45;

                return Stack(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.65),
                        BlendMode.srcOut,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.black,
                          ),
                          Center(
                            child: Container(
                              width: cutoutWidth,
                              height: cutoutHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cutout Border Corner Highlights
                    Center(
                      child: Container(
                        width: cutoutWidth,
                        height: cutoutHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 4. Focus Reticle Animation
          Center(
            child: AnimatedBuilder(
              animation: _focusController,
              builder: (context, child) {
                final scale = 1.0 + (_focusController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.yellow.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.yellow.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Header Control Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                  const Text(
                    'CAPTURE PREUVE PHOTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_off_rounded, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // 6. Snapping/Capture Loader
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Traitement de la photo...',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 7. Bottom Shutter Control Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20, left: 24, right: 24),
              color: Colors.black.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cadrez la preuve de livraison / de validation',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Simulated gallery thumbnail
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white54, size: 20),
                      ),
                      // Main Shutter Button
                      GestureDetector(
                        onTap: _triggerCapture,
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 4),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      // Camera Rotate
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.sync_rounded, color: Colors.white54, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 8. Flash effect
          if (_isShutterFlashing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

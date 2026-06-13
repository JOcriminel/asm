import 'package:flutter/material.dart';
import 'package:dux_front/core/theme/app_sizes.dart';

class ScannerOverlay extends StatefulWidget {
  final String title;

  const ScannerOverlay({
    super.key,
    required this.title,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onMockScanned(String barcode) {
    if (barcode.trim().isEmpty) return;
    Navigator.of(context).pop(barcode.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = (size.width < size.height ? size.width : size.height) * 0.65;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Viewfinder background mask
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                borderRadius: AppBorderRadius.roundedL,
              ),
              child: Stack(
                children: [
                  // Laser Line Animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (scanAreaSize - 4),
                        left: 2,
                        right: 2,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Header / Instruction
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'Barcode / QR Scanner',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapS,
                Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[300],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Simulation Controls (for emulators / virtual environment compatibility)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: AppBorderRadius.roundedL,
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Simulator - Enter Barcode Value',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  AppSpacing.gapM,
                  TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. SN-98234-X',
                      hintStyle: const TextStyle(color: Colors.white30),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _onMockScanned(_inputController.text),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                    onSubmitted: _onMockScanned,
                  ),
                  AppSpacing.gapM,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.casino),
                        label: const Text('Auto-Generate'),
                        onPressed: () {
                          final rand = DateTime.now().microsecondsSinceEpoch.toString().substring(7);
                          _onMockScanned('SN-$rand');
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        label: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

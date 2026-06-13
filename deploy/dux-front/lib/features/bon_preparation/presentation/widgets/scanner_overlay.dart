import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

class _ScannerOverlayState extends State<ScannerOverlay> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _inputController = TextEditingController();
  bool _hasScanned = false;
  bool _isSimulatorMode = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onScanned(String barcode) {
    if (_hasScanned || barcode.trim().isEmpty) return;
    _hasScanned = true;
    Navigator.of(context).pop(barcode.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = (size.width < size.height ? size.width : size.height) * 0.65;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The actual Camera Preview
          if (!_isSimulatorMode)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _onScanned(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            
          if (_isSimulatorMode)
            const Center(
              child: Icon(Icons.videocam_off, size: 64, color: Colors.white24),
            ),

          // Dark overlay with a transparent hole for the scanner
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: AppBorderRadius.roundedL,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border for the scanner
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                borderRadius: AppBorderRadius.roundedL,
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
                  'Scanner de Code',
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

          // Action buttons (Flash & Switch mode)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSimulatorMode)
                  Container(
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
                          'Saisie Manuelle',
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
                              onPressed: () => _onScanned(_inputController.text),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          onSubmitted: _onScanned,
                        ),
                      ],
                    ),
                  ),
                AppSpacing.gapL,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isSimulatorMode)
                      IconButton.filledTonal(
                        icon: const Icon(Icons.flash_on),
                        onPressed: () => _scannerController.toggleTorch(),
                      ),
                    IconButton.filledTonal(
                      icon: Icon(_isSimulatorMode ? Icons.camera_alt : Icons.keyboard),
                      onPressed: () {
                        setState(() {
                          _isSimulatorMode = !_isSimulatorMode;
                        });
                      },
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

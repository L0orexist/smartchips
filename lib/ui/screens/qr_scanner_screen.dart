import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';

/// Schermata per scansionare QR code del Banker
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        // Verifica che sia un indirizzo IP valido
        if (_isValidServerAddress(code)) {
          setState(() {
            _hasScanned = true;
          });
          
          // Ritorna l'indirizzo scansionato
          Navigator.of(context).pop(code);
          return;
        }
      }
    }
  }

  bool _isValidServerAddress(String address) {
    // Verifica formato IP:PORT o solo IP
    final ipPortPattern = RegExp(
      r'^(\d{1,3}\.){3}\d{1,3}(:\d{1,5})?$'
    );
    return ipPortPattern.hasMatch(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SCAN QR CODE',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          
          // Overlay
          _buildOverlay(),
          
          // Bottom instructions
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(
          borderColor: AppTheme.accentPrimary,
          borderWidth: 3,
          overlayColor: Colors.black.withValues(alpha: 0.7),
          borderRadius: 16,
          cutOutSize: 280,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 48,
              color: AppTheme.accentPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Point camera at Banker\'s QR code',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the QR code is well lit and in focus',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Toggle torch button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _controller.toggleTorch(),
                  icon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      return Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: state.torchState == TorchState.on
                            ? AppTheme.accentPrimary
                            : AppTheme.textSecondary,
                        size: 28,
                      );
                    },
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundCard,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _controller.switchCamera(),
                  icon: Icon(
                    Icons.flip_camera_ios,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundCard,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom shape for scanner overlay
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double cutOutSize;

  const _ScannerOverlayShape({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.borderRadius,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: rect.center,
              width: cutOutSize,
              height: cutOutSize,
            ),
            Radius.circular(borderRadius),
          ),
        ),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Paint overlay
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(getOuterPath(rect), paint);
    
    // Paint border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );
    
    // Draw corner brackets instead of full border
    final cornerLength = 40.0;
    final path = Path();
    
    // Top-left corner
    path.moveTo(cutOutRect.left, cutOutRect.top + cornerLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.quadraticBezierTo(
      cutOutRect.left, cutOutRect.top,
      cutOutRect.left + borderRadius, cutOutRect.top,
    );
    path.lineTo(cutOutRect.left + cornerLength, cutOutRect.top);
    
    // Top-right corner
    path.moveTo(cutOutRect.right - cornerLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.quadraticBezierTo(
      cutOutRect.right, cutOutRect.top,
      cutOutRect.right, cutOutRect.top + borderRadius,
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + cornerLength);
    
    // Bottom-right corner
    path.moveTo(cutOutRect.right, cutOutRect.bottom - cornerLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.quadraticBezierTo(
      cutOutRect.right, cutOutRect.bottom,
      cutOutRect.right - borderRadius, cutOutRect.bottom,
    );
    path.lineTo(cutOutRect.right - cornerLength, cutOutRect.bottom);
    
    // Bottom-left corner
    path.moveTo(cutOutRect.left + cornerLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.quadraticBezierTo(
      cutOutRect.left, cutOutRect.bottom,
      cutOutRect.left, cutOutRect.bottom - borderRadius,
    );
    path.lineTo(cutOutRect.left, cutOutRect.bottom - cornerLength);
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

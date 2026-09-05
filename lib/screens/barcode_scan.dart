import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';

/// Camera view that reads the barcode printed on a pack and pops it back.
///
/// Pops the code as a String, or null if the seller backed out. Reading the
/// code is all this screen does — looking it up is the caller's job, so the
/// camera can be released before the network call rather than sitting open
/// behind a spinner.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    // Retail packs carry EAN/UPC. Narrowing the formats stops the detector
    // firing on a QR code that happens to share the frame — this pack has one
    // right next to the barcode.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );

  /// The detector fires many times a second on the same code. Without this the
  /// screen would pop several times over and unwind the navigator too far.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final value = (barcode.rawValue ?? "").trim();
      if (value.isEmpty) continue;

      _handled = true;
      Navigator.pop(context, value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan barcode"),
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MynPalette.onYellow),
        centerTitle: true,
        elevation: 0,
        backgroundColor: MynPalette.brandYellow,
        systemOverlayStyle: MynPalette.overlayDark,
        iconTheme: IconThemeData(color: MynPalette.onYellow),
        actions: [
          IconButton(
            tooltip: "Torch",
            icon: Icon(Icons.flashlight_on_rounded, color: MynPalette.onYellow),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _buildError(error),
          ),
          _buildReticle(),
        ],
      ),
    );
  }

  /// A window over the live camera, so the seller knows where to hold the pack
  /// instead of guessing which part of the frame is being read.
  Widget _buildReticle() {
    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 36),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2.5),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Point at the barcode on the pack",
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MobileScannerException error) {
    // Nearly always a declined camera permission. Saying so beats a black
    // rectangle the seller cannot act on.
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(denied ? Icons.no_photography_outlined : Icons.error_outline,
                size: 46, color: Colors.white70),
            const SizedBox(height: 14),
            Text(
              denied
                  ? "MYN needs camera access to scan a barcode.\nAllow it in Settings > Apps > MYN The Seller."
                  : "The camera could not be opened.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
              ),
              child: const Text("Go back"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:secure_scan/historyscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String scannedCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Secure Scan',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Text(
                'Secure Every Scan, Trust Every Code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(height: 100),

            // 📷 Camera QR Scanner
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.deepPurple, width: 3),
              ),
              clipBehavior: Clip.hardEdge,
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    setState(() {
                      scannedCode = barcode.rawValue ?? 'Unknown';
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 10),
            Text(
              scannedCode.isEmpty ? 'Scan a QR code' : 'Scanned: $scannedCode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Bottom controls
            
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color iconColor, Color? bgColor, {double size = 50, double iconSize = 24}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(50)),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

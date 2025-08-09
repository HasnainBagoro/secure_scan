import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String scannedCode = '';
  bool isLoading = false;
  bool isScanning = false;

  final String apiKey = "AIzaSyA-uTJnmdBkQMipZOIeA92iGujHyoef2H0";

  String maskUrl(String url) {
    return url.replaceAll('.', '[.]');
  }

  Future<void> checkUrlSafety(String url) async {
  setState(() => isLoading = true);

  final requestBody = {
    "client": {"clientId": "flutter_app", "clientVersion": "1.0"},
    "threatInfo": {
      "threatTypes": [
        "MALWARE",
        "SOCIAL_ENGINEERING",
        "UNWANTED_SOFTWARE",
        "POTENTIALLY_HARMFUL_APPLICATION"
      ],
      "platformTypes": ["ANY_PLATFORM"],
      "threatEntryTypes": ["URL"],
      "threatEntries": [
        {"url": url}
      ]
    }
  };

  final response = await http.post(
    Uri.parse(
        "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(requestBody),
  );

  setState(() => isLoading = false);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.isNotEmpty) {
      // Dangerous Link
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text("Dangerous Link"),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              "This link may be unsafe:\n${maskUrl(url)}\n\n"
              "We recommend avoiding it unless you are sure it’s trustworthy.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startScanning();
              },
              child: const Text("Retry"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } else {
      // Safe Link
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Safe Link"),
            ],
          ),
          content: Text(
            "No known threats detected for:\n${maskUrl(url)}",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startScanning();
              },
              child: const Text("Retry"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              },
              child: const Text("Visit"),
            ),
          ],
        ),
      );
    }
  } else {
    debugPrint("Error checking URL: ${response.body}");
  }
}


  void startScanning() {
    setState(() {
      scannedCode = '';
      isScanning = true;
    });
  }

  void stopScanning() {
    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              '🔒 Secure Scan',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure Every Scan, Trust Every Code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Camera always visible
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple, width: 3),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (!isScanning) return; // only detect if scanning
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final code = barcode.rawValue ?? 'Unknown';
                          if (code != scannedCode &&
                              Uri.tryParse(code)?.hasAbsolutePath == true) {
                            stopScanning();
                            setState(() {
                              scannedCode = code;
                            });
                            checkUrlSafety(code);
                          }
                        }
                      },
                    ),
                  ),

                  // Loading overlay
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              "Checking link safety...",
                              style: TextStyle(color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scan button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  startScanning();
                },
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                ),
                label: Text(isScanning ? "Scanning..." : "Scan Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Last scanned code
            // if (!isLoading && scannedCode.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 20),
            //     child: Text(
            //       "Last scanned: ${maskUrl(scannedCode)}",
            //       style: const TextStyle(
            //           fontSize: 14,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

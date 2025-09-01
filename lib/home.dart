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
  final String mlApiUrl = "https://mlapi-production-1e77.up.railway.app/predict";

  String maskUrl(String url) {
    return url.replaceAll('.', '[.]');
  }

  /// Optional ML model check (used only if Google fails)
  Future<bool> checkUrlWithMLModel(String url) async {
    try {
      final response = await http.post(
        Uri.parse(mlApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('prediction')) {
          return data['prediction'].toString().toLowerCase() == 'malicious';
        } else if (data.containsKey('is_malicious')) {
          return data['is_malicious'] == true;
        } else if (data.containsKey('result')) {
          return data['result'].toString().toLowerCase() == 'malicious';
        }
      }
      return false;
    } catch (e) {
      debugPrint("ML Model API error: $e");
      return false;
    }
  }

  /// Check URL safety with Google Safe Browsing API
  Future<void> checkUrlSafety(String url) async {
    setState(() => isLoading = true);

    bool? isMalicious; // null = API failed
    String detectionSource = "Google Safe Browsing";

    try {
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
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.isNotEmpty) {
          isMalicious = true; // Google flagged it
        } else {
          isMalicious = false; // Safe according to Google
        }
      } else {
        isMalicious = null; // API didn’t respond properly
      }
    } catch (e) {
      debugPrint("Google Safe Browsing API error: $e");
      isMalicious = null; // Error / timeout
    }

    setState(() => isLoading = false);

    // Show dialog based on result
    if (isMalicious == true) {
      showDangerousDialog(url, detectionSource);
    } else if (isMalicious == false) {
      showSafeDialog(url, detectionSource);
    } else {
      showUnknownDialog(url, detectionSource);
    }
  }

  /// ---------- Dialogs ----------

  void showDangerousDialog(String url, String source) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Dangerous Link"),
          ],
        ),
        content: Text(
          "This link may be unsafe:\n${maskUrl(url)}\n\n"
          "Detection source: $source",
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
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void showSafeDialog(String url, String source) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Safe Link"),
          ],
        ),
        content: Text(
          "No known threats detected for:\n${maskUrl(url)}\n\n"
          "Detection source: $source",
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: const Text("Visit"),
          ),
        ],
      ),
    );
  }

  void showUnknownDialog(String url, String source) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.help, color: Colors.orange),
            SizedBox(width: 8),
            Text("Not Found"),
          ],
        ),
        content: Text(
          "No such entity in the database for:\n${maskUrl(url)}\n\n"
          "Detection source: $source",
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
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// ---------- Scanner Controls ----------

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
            const SizedBox(height: 50),
            const Text(
              'Secure Scan',
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
            const SizedBox(height: 50),

            // Camera view
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.deepPurple, width: 3),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (!isScanning) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final code = barcode.rawValue ?? 'Unknown';
                          if (code != scannedCode &&
                              Uri.tryParse(code)?.isAbsolute == true) {
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

            const SizedBox(height: 40),

            // Scan button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () {
                  if (!isScanning) {
                    startScanning();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: isScanning
                        ? Colors.deepPurple.withOpacity(0.8)
                        : Colors.deepPurple,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isScanning
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            key: ValueKey('icon'),
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

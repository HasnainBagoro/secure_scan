import 'dart:ffi';

import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to the next screen or home screen
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                  color: Color.fromARGB(255, 25, 56, 134),
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 100,
            ),
            Image.asset(
              'images/onboarding.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Secure Scan',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 80, right: 80),
              child: Text(
                'Secure. Scan. Protect. Your safety, one QR code at a time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to the next screen or home screen
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Next'),
              style: ElevatedButton.styleFrom(
                iconColor: Color.fromARGB(255, 25, 56, 134),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

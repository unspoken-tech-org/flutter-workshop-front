import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  static const route = '/splash';

  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text(
              'Restaurando sessão...',
              style: TextStyle(fontSize: 14, color: Color(0xFF49454F)),
            ),
          ],
        ),
      ),
    );
  }
}

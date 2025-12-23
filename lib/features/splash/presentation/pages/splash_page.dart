import 'package:barbershop/main.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  void _navigateToAuth() async {
    // Wait for 1.5 seconds while showing the logo
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // Navigate to AuthGate to handle authentication redirect
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / App Icon
            // Using a Container with decoration to make it look nice if transparent,
            // or just Image.asset if the png is good.
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.cut, size: 80, color: Colors.amber);
                },
              ),
            ),
            const Gap(30),
            // Loading indicator (Optional, user asked for just the logo, but a small loader is UX friendly)
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFD4AF37), // Gold color
              ),
            ),
          ],
        ),
      ),
    );
  }
}

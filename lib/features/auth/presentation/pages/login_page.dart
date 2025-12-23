import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:barbershop/features/auth/data/auth_service.dart'; // Import AuthService
import 'package:barbershop/shared/services/firestore_service.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_home_page.dart';
import 'package:barbershop/main.dart'; // Circular dependency if not careful, but okay for navigation for now.
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // Logo
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image: AssetImage('assets/icon/app_icon.png'),
                              fit: BoxFit.contain,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(32),
                      Text(
                        'Antonio\nBarber Shop',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                      ),
                      const Gap(8),
                      Text(
                        'Agende seu horário com estilo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const Spacer(),
                      // Google Login Button (Hide on Windows as it's not supported natively yet)
                      if (kIsWeb || !Platform.isWindows)
                        OutlinedButton(
                          onPressed: () async {
                            // Real Google Login
                            print('Attempting Google Login...');
                            final authService = AuthService();
                            try {
                              final userCredential =
                                  await authService.signInWithGoogle();
                              print(
                                  'Google Login Result: ${userCredential?.user?.email}');

                              if (userCredential != null && context.mounted) {
                                print('Saving Google user to Firestore...');
                                // Save user to Firestore
                                await FirestoreService()
                                    .saveUser(userCredential.user!);
                                print(
                                    'Google User saved. Checking Admin role...');

                                if (authService.isAdmin) {
                                  print(
                                      'User is Admin. Navigating to AdminHomePage.');
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const AdminHomePage()),
                                  );
                                } else {
                                  print(
                                      'User is Client. Navigating to MainScreen.');
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const MainScreen()),
                                  );
                                }
                              } else {
                                print(
                                    'Google Login failed: userCredential is null (likely canceled)');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Login falhou ou cancelado')),
                                  );
                                }
                              }
                            } catch (e) {
                              print('EXCEPTION during Google Login: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Erro no login Google: $e')),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Placeholder for G icon if we don't have svg asset yet
                              const Icon(Icons.g_mobiledata,
                                  size: 28, color: Colors.blue),
                              const Gap(8),
                              Text(
                                'Entrar com Google',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      if (kIsWeb || !Platform.isWindows) const Gap(16),
                      // Phone Login Button
                      ElevatedButton(
                        onPressed: () async {
                          // Guest Login
                          print('Attempting Guest Login...');
                          final authService = AuthService();
                          try {
                            final userCredential =
                                await authService.signInAnonymously();
                            print(
                                'Guest Login Result: ${userCredential?.user?.uid}');

                            if (userCredential != null && context.mounted) {
                              print('Saving guest user to Firestore...');
                              // Save user to Firestore with timeout
                              try {
                                await FirestoreService()
                                    .saveUser(userCredential.user!)
                                    .timeout(const Duration(seconds: 5));
                                print('Guest User saved successfully.');
                              } catch (e) {
                                print(
                                    'WARNING: Failed to save user to Firestore (or timed out): $e');
                                // Continue anyway to allow access even if DB write fails
                              }

                              print('Navigating to MainScreen...');
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const MainScreen()),
                              );
                            } else {
                              print(
                                  'Guest Login failed: userCredential is null');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Falha ao entrar como convidado')),
                                );
                              }
                            }
                          } catch (e) {
                            print('EXCEPTION during Guest Login: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro no login: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white),
                            const Gap(8),
                            Text(
                              'Entrar como Convidado',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(48),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

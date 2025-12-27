import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import 'package:barbershop/firebase_options.dart';
import 'package:barbershop/core/theme/app_theme.dart';
import 'package:barbershop/shared/services/push_notification_service.dart';
import 'package:barbershop/shared/widgets/custom_bottom_nav.dart';

// Pages
import 'package:barbershop/features/auth/data/auth_service.dart';
import 'package:barbershop/features/auth/presentation/pages/login_page.dart';
import 'package:barbershop/features/home/presentation/pages/home_page.dart';
import 'package:barbershop/features/appointments/presentation/pages/appointments_page.dart';
import 'package:barbershop/features/profile/presentation/pages/profile_page.dart';
import 'package:barbershop/features/admin/presentation/pages/admin_home_page.dart';
import 'package:barbershop/features/splash/presentation/pages/splash_page.dart';
import 'package:barbershop/features/products/presentation/pages/products_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('FIREBASE PROJECT ID: ${Firebase.app().options.projectId}');

  // Enable Firestore Logging
  FirebaseFirestore.setLoggingEnabled(true);

  // Initialize Push Notifications (Only on Mobile)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      print('Failed to initialize Push Notifications: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbershop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      // Initial Entry Point is the Splash Screen
      home: const SplashPage(),
    );
  }
}

// AuthGate handles the logic: If logged in -> Home/Admin, if logged out -> Login
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Verify if connection is valid
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // User is logged in
          if (snapshot.data!.email == 'admin@barber.com') {
            return const AdminHomePage();
          }
          return const MainScreen();
        }

        // User is expected to log in
        return const LoginPage();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const AppointmentsPage(),
    const ProductsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

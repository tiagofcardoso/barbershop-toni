import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:barbershop/core/theme/app_theme.dart';
import 'package:barbershop/features/appointments/presentation/pages/appointments_page.dart';
import 'package:barbershop/shared/services/push_notification_service.dart';
import 'package:barbershop/features/auth/presentation/pages/login_page.dart';
import 'package:barbershop/features/profile/presentation/pages/profile_page.dart';
import 'package:barbershop/features/home/presentation/pages/home_page.dart';
import 'package:barbershop/shared/widgets/custom_bottom_nav.dart';
import 'package:barbershop/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('FIREBASE PROJECT ID: ${Firebase.app().options.projectId}');

  // Enable Firestore Logging
  FirebaseFirestore.setLoggingEnabled(true);

  // Test Read
  print('TEST: Attempting to read users collection...');
  FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'barbershop-native')
      .collection('users')
      .get()
      .then((snapshot) {
    print('TEST: Successfully read ${snapshot.docs.length} users.');
  }).catchError((e) {
    print('TEST: FAILED to read users: $e');
  });

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
      home: const LoginPage(),
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

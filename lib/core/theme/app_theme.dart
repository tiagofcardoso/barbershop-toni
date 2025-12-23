import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        primary: Colors.black,
        secondary: Colors.grey[800]!,
        background: Colors.white,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

import 'package:barbershop/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart'; // We'll need to mock network images or use a wrapper, but for now let's just use image_test_utils concepts or similar. Actually, since we use NetworkImage, tests will fail without mocking http.
// Wait, I didn't add network_image_mock dependency. I should probably just check for widgets and not worry about actual image rendering, but NetworkImage throws in tests.
// Let's use a simple override or just catch the error if possible, or better, add the dev dependency.
// For now, I'll try to use a test that doesn't trigger the image loading or expect it to fail gracefully, but standard Image.network throws.
// Let's add mock_network_image_2 or similar if needed, OR just wrap the image widget in something swappable.
// Actually, I can just override HttpOverrides.

import 'dart:io';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('HomePage renders correctly with Grid and BottomNav',
      (WidgetTester tester) async {
    // We need to mock network images because ServiceCard uses NetworkImage.
    // Since I cannot easily add packages without approval/task update and I want to be quick,
    // I will try to run the test. If it fails on network image, I will add the package.
    // Ideally, I should have added `network_image_mock` in the beginning.

    // Let's rely on the fact that we can just pump the widget.
    // To safe-guard against NetworkImage issues in tests, a common trick is to override the http client
    // to return 404 or empty image, but `NetworkImage` in Flutter is picky.

    // Better approach: modify ServiceCard to handle errors or use a placeholder in tests?
    // No, I shouldn't change prod code just for this if I can avoid it.

    // Let's try running it. If it fails, I'll add the dependency `image_test_utils` or `network_image_mock`.

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(const MyApp());

      // Verify Home Page Title
      expect(find.text('Agende seu corte'), findsOneWidget);
      expect(find.text('Bem vindo,'), findsOneWidget);

      // Verify Grid exists
      expect(find.byType(SliverGrid), findsOneWidget);

      // Verify Service Cards (from Mock Data)
      expect(find.text('Corte Degradê'), findsOneWidget);
      expect(find.text('Barba Completa'), findsOneWidget);

      // Scroll to find the 3rd item
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Combo (Corte + Barba)'), findsWidgets);

      // Verify Bottom Navigation
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });
  });
}

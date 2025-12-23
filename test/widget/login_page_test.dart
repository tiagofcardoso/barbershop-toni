import 'package:barbershop/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify Title
    expect(find.text('Antonio\nBarber Shop'), findsOneWidget);
    expect(find.text('Agende seu horário com estilo'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Entrar com Celular'), findsOneWidget);

    // Verify Icons
    expect(find.byIcon(Icons.g_mobiledata),
        findsOneWidget); // We used this placeholder
    expect(find.byIcon(Icons.phone_iphone_rounded), findsOneWidget);
  });
}

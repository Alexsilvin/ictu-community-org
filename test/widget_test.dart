import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ictu_community_org/app.dart';
import 'package:ictu_community_org/features/auth/screens/splash_screen.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';

void main() {
  testWidgets('Splash transitions to welcome screen', (
    WidgetTester tester,
  ) async {
    // Ensure the test surface is large enough for the WelcomeScreen layout.
    // Without this, the Column on WelcomeScreen can overflow in the default
    // test viewport and fail the test.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const IctuCommunityApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Welcome to ICT-U'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}

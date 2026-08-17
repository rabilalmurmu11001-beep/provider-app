import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_app/screens/auth/signin_screen.dart';
import 'package:provider_app/theme.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      home: child,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
    );
  }

  testWidgets('LoginScreen initial state is Email Address and Password', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting(child: const LoginScreen()));

    // Verify initial selectors
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('One-Time OTP'), findsOneWidget);

    // Verify initial fields (Email and Password mode)
    expect(find.text('Operator Business Email'), findsOneWidget);
    expect(find.text('Access Security Pin'), findsOneWidget);
    expect(find.text('Operator Mobile Number'), findsNothing);
    expect(find.text('One-Time Verification Code'), findsNothing);
  });

  testWidgets('LoginScreen switches to Mobile Number with Password', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting(child: const LoginScreen()));

    // Tap Mobile Number selector
    await tester.tap(find.text('Mobile Number'));
    await tester.pumpAndSettle();

    // Verify fields updated
    expect(find.text('Operator Mobile Number'), findsOneWidget);
    expect(find.text('Access Security Pin'), findsOneWidget);
    expect(find.text('Operator Business Email'), findsNothing);
    expect(find.text('One-Time Verification Code'), findsNothing);
  });

  testWidgets('LoginScreen switches to Email Address with OTP', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting(child: const LoginScreen()));

    // Tap One-Time OTP selector
    await tester.tap(find.text('One-Time OTP'));
    await tester.pumpAndSettle();

    // Verify fields updated
    expect(find.text('Operator Business Email'), findsOneWidget);
    expect(find.text('Access Security Pin'), findsNothing);
    expect(find.text('Request Verification Code'), findsOneWidget);
  });

  testWidgets('LoginScreen switches to Mobile Number with OTP', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetForTesting(child: const LoginScreen()));

    // Tap Mobile Number
    await tester.tap(find.text('Mobile Number'));
    await tester.pumpAndSettle();

    // Tap One-Time OTP
    await tester.tap(find.text('One-Time OTP'));
    await tester.pumpAndSettle();

    // Verify fields updated
    expect(find.text('Operator Mobile Number'), findsOneWidget);
    expect(find.text('Access Security Pin'), findsNothing);
    expect(find.text('Request Verification Code'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_app/screens/profile_screen.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import 'package:provider_app/stores/kyc_providers.dart';
import 'package:provider_app/stores/providers.dart';
import 'package:provider_app/theme.dart';

void main() {
  Widget createProfileScreen({
    required Map<String, dynamic> userProfileData,
  }) {
    return ProviderScope(
      overrides: [
        providerProfileProvider.overrideWith((ref) => userProfileData),
        providerProfileAsyncProvider.overrideWith((ref) async => userProfileData),
        kycStatusAsyncProvider.overrideWith((ref) async => {
              'isVerified': true,
              'kycStatus': 'approved',
            }),
        providerAssignedBookingsProvider('completed')
            .overrideWith((ref) async => []),
        providerAssignedBookingsProvider('assigned')
            .overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        home: const ProfileScreen(),
      ),
    );
  }

  testWidgets(
      'ProfileScreen displays Verified status when email and phone are verified',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'user-1',
      'username': 'Rahul Sharma',
      'email': 'rahul@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'service_provider',
      'address': 'Main Hub Street',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('rahul@example.com'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);

    // Both should display 'Verified' badges
    expect(find.text('Verified'), findsNWidgets(2));
    expect(find.text('Verify'), findsNothing);
  });

  testWidgets(
      'ProfileScreen displays Pending status and Verify button when unverified',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'user-1',
      'username': 'Rahul Sharma',
      'email': 'rahul@example.com',
      'mobile': '9876543210',
      'isEmailVerified': false,
      'isPhoneVerified': false,
      'role': 'service_provider',
      'address': 'Main Hub Street',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    // Both should display 'Pending' badges and 'Verify' buttons
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Verify'), findsNWidgets(2));
  });

  testWidgets(
      'Opening edit profile modal renders email & mobile fields with OTP triggers',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'user-1',
      'username': 'Rahul Sharma',
      'email': 'rahul@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'service_provider',
      'address': 'Main Hub Street',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    // Tap on 'Edit Info'
    final editInfoButton = find.text('Edit Info');
    expect(editInfoButton, findsOneWidget);
    await tester.tap(editInfoButton);
    await tester.pumpAndSettle();

    // Verify modal elements
    expect(find.text('Edit Provider Profile'), findsOneWidget);
    expect(find.text('FULL NAME / DISPLAY NAME'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('CONTACT MOBILE NUMBER'), findsOneWidget);
    expect(find.text('PRIMARY OPERATIONAL ADDRESS'), findsOneWidget);

    // Initial state: both are verified
    expect(find.text('Verified'), findsWidgets);

    // Now change the email address field to something new
    final emailField = find.widgetWithText(TextFormField, 'rahul@example.com');
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'newemail@example.com');
    await tester.pumpAndSettle();

    // After modifying email, it should show 'Requires OTP' and 'Verify with OTP'
    expect(find.text('Requires OTP'), findsOneWidget);
    expect(find.text('Verify with OTP'), findsOneWidget);
  });
}

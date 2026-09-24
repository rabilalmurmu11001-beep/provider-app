import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_app/screens/kyc_screen.dart';
import 'package:provider_app/stores/kyc_providers.dart';
import 'package:provider_app/theme.dart';

void main() {
  Widget createKycScreen({
    required Map<String, dynamic> kycDetailsData,
  }) {
    return ProviderScope(
      overrides: [
        kycDetailsAsyncProvider.overrideWith((ref) async => kycDetailsData),
      ],
      child: MaterialApp(
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        home: const KycScreen(),
      ),
    );
  }

  testWidgets('KycScreen renders document upload cards when not submitted',
      (WidgetTester tester) async {
    final mockData = {
      'isVerified': false,
      'kycStatus': 'not_submitted',
      'kyc': null,
    };

    await tester.pumpWidget(createKycScreen(kycDetailsData: mockData));
    await tester.pumpAndSettle();

    // Verify header status
    expect(find.text('KYC Verification Needed 🪪'), findsOneWidget);

    // Verify sections
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('1. Identity Proof (POI) *'), findsOneWidget);
    expect(find.text('2. Address Proof (POA) *'), findsOneWidget);

    // Verify document upload cards and buttons
    expect(find.text('Identity Document Front Side *'), findsOneWidget);
    expect(find.text('Identity Document Back Side (Optional)'), findsOneWidget);
    expect(find.text('Address Proof Document (Front / Page 1) *'), findsOneWidget);
    expect(find.text('Address Proof Document (Back / Page 2 - Optional)'),
        findsOneWidget);
    expect(find.text('Selfie or Portrait Photo (Optional)'), findsOneWidget);

    // Verify Camera & Gallery action buttons exist
    expect(find.text('Camera'), findsWidgets);
    expect(find.text('Gallery'), findsWidgets);

    // Verify submit button
    expect(find.text('Submit KYC for Verification'), findsOneWidget);
  });

  testWidgets('KycScreen renders submitted documents in review summary',
      (WidgetTester tester) async {
    final mockData = {
      'isVerified': false,
      'kycStatus': 'pending',
      'kyc': {
        'fullName': 'Ramesh Kumar',
        'identityDocumentType': 'aadhaar',
        'identityDocumentNumber': '123456789012',
        'identityDocumentFrontUrl': 'https://s3.amazonaws.com/kyc/id_front.jpg',
        'identityDocumentBackUrl': 'https://s3.amazonaws.com/kyc/id_back.jpg',
        'addressDocumentType': 'utility_bill',
        'addressDocumentNumber': 'ELEC12345',
        'addressDocumentFrontUrl': 'https://s3.amazonaws.com/kyc/addr_front.jpg',
        'addressDocumentBackUrl': null,
        'selfieUrl': 'https://s3.amazonaws.com/kyc/selfie.jpg',
      },
    };

    await tester.pumpWidget(createKycScreen(kycDetailsData: mockData));
    await tester.pumpAndSettle();

    // Verify review header
    expect(find.text('Verification Under Review ⏳'), findsOneWidget);
    expect(find.text('SUBMISSION DETAILS (QUEUED)'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);

    // Verify attachments preview section
    expect(find.text('SUBMITTED DOCUMENT ATTACHMENTS'), findsOneWidget);
    expect(find.text('Identity Front'), findsOneWidget);
    expect(find.text('Identity Back'), findsOneWidget);
    expect(find.text('Address Proof'), findsOneWidget);
    expect(find.text('Selfie Photo'), findsOneWidget);
  });
}

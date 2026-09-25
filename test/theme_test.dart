import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider_app/screens/profile_screen.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import 'package:provider_app/stores/kyc_providers.dart';
import 'package:provider_app/stores/providers.dart';
import 'package:provider_app/theme.dart';

void main() {
  setUp(() {
    themeModeNotifier.value = ThemeMode.system;
  });

  tearDown(() {
    themeModeNotifier.value = ThemeMode.system;
  });

  test('themeModeNotifier defaults to ThemeMode.system', () {
    expect(themeModeNotifier.value, ThemeMode.system);
  });

  test('setThemeMode and toggleTheme update themeModeNotifier', () {
    setThemeMode(ThemeMode.dark);
    expect(themeModeNotifier.value, ThemeMode.dark);

    setThemeMode(ThemeMode.light);
    expect(themeModeNotifier.value, ThemeMode.light);

    toggleTheme(true);
    expect(themeModeNotifier.value, ThemeMode.dark);

    toggleTheme(false);
    expect(themeModeNotifier.value, ThemeMode.light);

    setThemeMode(ThemeMode.system);
    expect(themeModeNotifier.value, ThemeMode.system);
  });

  testWidgets(
      'AppTheme definitions use Material 3 and proper color schemes',
      (tester) async {
    final light = AppTheme.getLightTheme();
    final dark = AppTheme.getDarkTheme();

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);

    expect(light.colorScheme.primary, AppColors.primary);
    expect(dark.colorScheme.primary, AppColors.primary);

    expect(light.colorScheme.surface, AppColors.lightCard);
    expect(dark.colorScheme.surface, AppColors.darkCard);
  });

  testWidgets(
      'ProfileScreen renders 3-mode Appearance Theme dropdown and updates on change',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'user-1',
      'username': 'Rahul Sharma',
      'email': 'rahul@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'service_provider',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerProfileProvider.overrideWith((ref) => mockUser),
          providerProfileAsyncProvider.overrideWith((ref) async => mockUser),
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
      ),
    );
    await tester.pumpAndSettle();

    // Verify Appearance Theme section is visible
    final themeSection = find.text('Appearance Theme');
    await tester.ensureVisible(themeSection);
    expect(themeSection, findsOneWidget);
    expect(find.text('System (Default)'), findsOneWidget);

    // Find and tap the DropdownButton
    final dropdown = find.byType(DropdownButton<ThemeMode>);
    expect(dropdown, findsOneWidget);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // Verify all 3 options are displayed in dropdown
    expect(find.text('System'), findsWidgets);
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsWidgets);

    // Select Dark
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(themeModeNotifier.value, ThemeMode.dark);
    expect(find.text('Dark Mode Active'), findsOneWidget);

    // Select Light
    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();

    expect(themeModeNotifier.value, ThemeMode.light);
    expect(find.text('Light Mode Active'), findsOneWidget);

    // Select System
    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();

    expect(themeModeNotifier.value, ThemeMode.system);
    expect(find.text('System (Default)'), findsOneWidget);
  });
}

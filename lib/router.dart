import 'package:go_router/go_router.dart';
import 'package:provider_app/screens/addservice_screen.dart';
import 'package:provider_app/screens/auth/onboarding_screen.dart';
import 'package:provider_app/screens/auth/signup_screen.dart';
import 'package:provider_app/screens/auth/splash_screen.dart';
import 'package:provider_app/screens/bookingDetails_screen.dart';
import 'package:provider_app/screens/chat_screen.dart';
import 'package:provider_app/screens/earning_screen.dart';
import 'package:provider_app/screens/profile_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/dashboard_screens.dart';
import 'screens/bookings_screens.dart';
import 'screens/catalog_screens.dart';
import 'widgets/console_shell.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ResponsiveConsoleShell(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingsScreen(),
        ),
        GoRoute(
          path: '/bookings/detail',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ??
                (state.extra is String ? state.extra as String : null);
            final data = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : null;
            return BookingDetailScreen(
              bookingId: id,
              initialBookingData: data,
            );
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final roomId = state.uri.queryParameters['roomId'] ??
                extra?['roomId']?.toString() ??
                extra?['bookingId']?.toString() ??
                '';
            final recipientName = state.uri.queryParameters['recipientName'] ??
                extra?['recipientName']?.toString();
            final recipientPhoto = state.uri.queryParameters['recipientPhoto'] ??
                extra?['recipientPhoto']?.toString();
            final recipientId = state.uri.queryParameters['recipientId'] ??
                extra?['recipientId']?.toString();
            return ChatScreen(
              roomId: roomId,
              recipientName: recipientName,
              recipientPhoto: recipientPhoto,
              recipientId: recipientId,
            );
          },
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesScreen(),
        ),
        GoRoute(
          path: '/services/add',
          builder: (context, state) => const AddServiceScreen(),
        ),
        GoRoute(
          path: '/earnings',
          builder: (context, state) => const EarningsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

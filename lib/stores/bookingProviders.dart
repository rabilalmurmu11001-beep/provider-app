import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/bookingServices.dart';

/// Provider for available unassigned bookings
final availableBookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(providerBookingServiceProvider);
  return await service.getAvailableBookings();
});

/// Provider for assigned bookings filtered by status (null for all assigned)
final providerAssignedBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      status,
    ) async {
      final service = ref.watch(providerBookingServiceProvider);
      return await service.getAssignedBookings(status: status);
    });

/// Provider for a single booking detail by ID
final providerBookingDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, bookingId) async {
      final service = ref.watch(providerBookingServiceProvider);
      return await service.getBookingById(bookingId);
    });

/// Currently selected active booking for quick access in details screen
final selectedBookingProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

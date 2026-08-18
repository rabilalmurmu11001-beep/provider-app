import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_app/network.dart';

final providerBookingServiceProvider = Provider<ProviderBookingService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProviderBookingService(dio);
});

class ProviderBookingService {
  final Dio _dio;

  ProviderBookingService(this._dio);

  /// Fetch bookings assigned to the current provider, optionally filtered by status
  /// (e.g. 'accepted', 'in_progress', 'completed', 'cancelled')
  Future<List<Map<String, dynamic>>> getAssignedBookings({
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'r': 'provider'};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final response = await _dio.get(
        '/provider/bookings',
        queryParameters: queryParams,
      );
      if (response.data is Map<String, dynamic> &&
          response.data['bookings'] is List) {
        return List<Map<String, dynamic>>.from(response.data['bookings']);
      }
      return [];
    } catch (err) {
      rethrow;
    }
  }

  /// Fetch unassigned / available requested bookings in the system that a provider can claim
  Future<List<Map<String, dynamic>>> getAvailableBookings() async {
    try {
      final response = await _dio.get(
        '/provider/bookings/available',
        queryParameters: {'r': 'provider'},
      );
      if (response.data is Map<String, dynamic> &&
          response.data['bookings'] is List) {
        return List<Map<String, dynamic>>.from(response.data['bookings']);
      }
      return [];
    } catch (err) {
      rethrow;
    }
  }

  /// Fetch a single booking by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final response = await _dio.get(
        '/provider/bookings/$bookingId',
        queryParameters: {'r': 'provider'},
      );
      if (response.data is Map<String, dynamic> &&
          response.data['booking'] != null) {
        return Map<String, dynamic>.from(response.data['booking']);
      }
      return null;
    } catch (err) {
      rethrow;
    }
  }

  /// Accept an available booking
  Future<Response> acceptBooking(String bookingId) async {
    try {
      return await _dio.patch(
        '/provider/bookings/$bookingId/accept',
        queryParameters: {'r': 'provider'},
      );
    } catch (err) {
      rethrow;
    }
  }

  /// Start an accepted booking (sets status to in_progress)
  Future<Response> startBooking(String bookingId) async {
    try {
      return await _dio.patch(
        '/provider/bookings/$bookingId/start',
        queryParameters: {'r': 'provider'},
      );
    } catch (err) {
      rethrow;
    }
  }

  /// Complete an in-progress booking (sets status to completed)
  Future<Response> completeBooking(String bookingId) async {
    try {
      return await _dio.patch(
        '/provider/bookings/$bookingId/complete',
        queryParameters: {'r': 'provider'},
      );
    } catch (err) {
      rethrow;
    }
  }

  /// Cancel a booking with a reason
  Future<Response> cancelBooking(String bookingId, String reason) async {
    try {
      return await _dio.patch(
        '/provider/bookings/$bookingId/cancel',
        data: {'reason': reason},
        queryParameters: {'r': 'provider'},
      );
    } catch (err) {
      rethrow;
    }
  }
}

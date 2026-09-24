import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_app/network.dart';

final kycServiceProvider = Provider<KycService>((ref) {
  final dio = ref.watch(dioProvider);
  return KycService(dio);
});

class KycService {
  final Dio _dio;

  KycService(this._dio);

  /// Fetch quick KYC verification status (status, isVerified, rejectionReason)
  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final response = await _dio.get('/service-providers/kyc/status');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': false, 'status': 'not_submitted', 'isVerified': false};
    } catch (err) {
      rethrow;
    }
  }

  /// Fetch full KYC submission details for the current provider
  Future<Map<String, dynamic>> getMyKyc() async {
    try {
      final response = await _dio.get('/service-providers/kyc/me');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': false, 'kycStatus': 'not_submitted', 'isVerified': false};
    } catch (err) {
      rethrow;
    }
  }

  /// Submit or update KYC document details (Identity Proof + Address Proof)
  Future<Map<String, dynamic>> submitKyc({
    required String identityDocumentType,
    required String identityDocumentNumber,
    required String identityDocumentFrontUrl,
    String? identityDocumentBackUrl,
    required String addressDocumentType,
    String? addressDocumentNumber,
    required String addressDocumentFrontUrl,
    String? addressDocumentBackUrl,
    String? selfieUrl,
    required String fullName,
    String? dob,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'identityDocumentType': identityDocumentType,
        'identityDocumentNumber': identityDocumentNumber.trim(),
        'identityDocumentFrontUrl': identityDocumentFrontUrl.trim(),
        'addressDocumentType': addressDocumentType,
        'addressDocumentFrontUrl': addressDocumentFrontUrl.trim(),
        'fullName': fullName.trim(),
      };

      if (identityDocumentBackUrl != null &&
          identityDocumentBackUrl.trim().isNotEmpty) {
        payload['identityDocumentBackUrl'] = identityDocumentBackUrl.trim();
      }
      if (addressDocumentNumber != null &&
          addressDocumentNumber.trim().isNotEmpty) {
        payload['addressDocumentNumber'] = addressDocumentNumber.trim();
      }
      if (addressDocumentBackUrl != null &&
          addressDocumentBackUrl.trim().isNotEmpty) {
        payload['addressDocumentBackUrl'] = addressDocumentBackUrl.trim();
      }
      if (selfieUrl != null && selfieUrl.trim().isNotEmpty) {
        payload['selfieUrl'] = selfieUrl.trim();
      }
      if (dob != null && dob.trim().isNotEmpty) {
        payload['dob'] = dob.trim();
      }

      final response = await _dio.post(
        '/service-providers/kyc',
        data: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (err) {
      rethrow;
    }
  }

  /// Update provider operational status ('available', 'busy', 'offline')
  Future<Map<String, dynamic>> updateProviderStatus(String status) async {
    try {
      final response = await _dio.patch(
        '/service-providers/status',
        data: {'providerStatus': status},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (err) {
      rethrow;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kyc_service.dart';

/// Provider fetching quick KYC status of the logged in provider
final kycStatusAsyncProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final kycService = ref.watch(kycServiceProvider);
  return await kycService.getKycStatus();
});

/// Provider fetching full KYC submission details
final kycDetailsAsyncProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final kycService = ref.watch(kycServiceProvider);
  return await kycService.getMyKyc();
});

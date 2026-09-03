import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/authServices.dart';

/// StateProvider holding the current cached provider profile data
final providerProfileProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// FutureProvider that fetches the provider's profile from the API and updates state
final providerProfileAsyncProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  try {
    final response = await authService.getUserProfile();
    if (response.data is Map<String, dynamic>) {
      final user = response.data['user'];
      if (user is Map<String, dynamic>) {
        ref.read(providerProfileProvider.notifier).state = user;
        return user;
      }
    }
    return null;
  } catch (err) {
    rethrow;
  }
});
 
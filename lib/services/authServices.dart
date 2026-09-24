import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_app/network.dart';
import 'package:provider_app/secureStorage.dart';
import 'package:provider_app/services/notification_service.dart';

/// A template for creating services that use the Dio instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Response> emaillogin(String username, String password) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/email/login?r=provider",
        data: {"email": username, "password": password},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> phonelogin(String username, String password) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/phone/login?r=provider",
        data: {"mobile": username, "password": password},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> signup(
    String username,
    String password,
    String email, [
    String? mobile,
  ]) async {
    try {
      final Map<String, dynamic> data = {
        "username": username,
        "password": password,
        "email": email,
      };
      if (mobile != null && mobile.trim().isNotEmpty) {
        data["mobile"] = mobile.trim();
      }

      Response<dynamic> result = await _dio.post(
        "/auth/signup?r=provider",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify signup OTP (email and/or phone) to complete user registration
  Future<Response> verifySignupOtp({
    String? signupToken,
    String? email,
    String? emailOtp,
    String? phoneOtp,
    String? otp,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (signupToken != null && signupToken.isNotEmpty) {
        data['signupToken'] = signupToken;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }
      if (emailOtp != null && emailOtp.isNotEmpty) {
        data['emailOtp'] = emailOtp;
      }
      if (phoneOtp != null && phoneOtp.isNotEmpty) {
        data['phoneOtp'] = phoneOtp;
      }
      if (otp != null && otp.isNotEmpty) {
        data['otp'] = otp;
      }

      Response<dynamic> result = await _dio.post(
        "/auth/verify-signup-otp",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Resend signup OTP for email, phone, or both
  Future<Response> resendSignupOtp({
    String? signupToken,
    String? email,
    String type = 'all',
  }) async {
    try {
      final Map<String, dynamic> data = {'type': type};
      if (signupToken != null && signupToken.isNotEmpty) {
        data['signupToken'] = signupToken;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }

      Response<dynamic> result = await _dio.post(
        "/auth/resend-signup-otp",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }


  Future<Response> getUserProfile() async {
    try {
      Response<dynamic> result = await _dio.get("/users/profile/me?r=provider");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Request an OTP for the given identifier (email or phone)
  Future<Response> requestOtp(String identifier) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/request-otp?r=provider",
        data: {"email": identifier},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify the OTP code for the given identifier
  Future<Response> verifyOtp(String identifier, String code) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/verify-otp?r=provider",
        data: {"identifier": identifier, "otp": code},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> updateUserInfo(
    String username,
    int age,
    String gender,
    String address,
  ) async {
    try {
      Response<dynamic> result = await _dio.patch(
        "/users/update/me?r=provider",
        data: {
          "username": username,
          "age": age,
          "gender": gender,
          "address": address,
        },
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Update user profile with arbitrary allowed fields (username, mobile, gender, age, photo, address)
  Future<Response> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      Response<dynamic> result = await _dio.patch(
        "/users/update/me?r=provider",
        data: updatedData,
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Update user profile picture URL
  Future<Response> updateProfilePicture(String photoUrl) async {
    return updateUserProfile({'photo': photoUrl});
  }

  /// Send password reset email
  Future<Response> resetPassword(String email) async {
    try {
      final result = await _dio.post(
        "/auth/password/reset?r=provider",
        data: {"email": email},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      final tokenRepository = TokenRepository();
      await NotificationService.instance.deleteTokenFromBackend();
      await tokenRepository.deleteToken();
      return true;
    } catch (err) {
      return false;
    }
  }
}

import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'package:get/get.dart' hide Response;
import '../../services/storage_service.dart';

/// Auth repository - Email + Password + 2FA
class AuthRepo {
  final ApiClient _api;

  AuthRepo(this._api);

  /// Register with email + password
  /// POST /auth/register { email, password, confirmPassword }
  Future<RegisterResponseModel> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _api.post(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    
    _checkResponse(response);
    return RegisterResponseModel.fromJson(response.data);
  }

  /// Login with email + password
  /// POST /auth/login { email, password }
  /// Returns tokens OR requires2FA: true
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );
    
    _checkResponse(response);
    return LoginResponseModel.fromJson(response.data);
  }

  /// Verify 2FA code
  /// POST /auth/verify-2fa { userId, code }
  Future<Verify2FAResponseModel> verify2FA({
    required String userId,
    required String code,
  }) async {
    final response = await _api.post(
      ApiEndpoints.authVerify2FA,
      data: {
        'userId': userId,
        'code': code,
      },
    );
    
    _checkResponse(response);
    return Verify2FAResponseModel.fromJson(response.data);
  }

  /// Resend 2FA code
  /// POST /auth/resend-2fa { userId }
  Future<AuthSuccessModel> resend2FA({required String userId}) async {
    final response = await _api.post(
      ApiEndpoints.authResend2FA,
      data: {'userId': userId},
    );
    
    _checkResponse(response);
    return AuthSuccessModel.fromJson(response.data);
  }

  /// Enable 2FA (requires auth)
  /// POST /auth/enable-2fa
  Future<AuthSuccessModel> enable2FA() async {
    final response = await _api.post(ApiEndpoints.authEnable2FA);
    _checkResponse(response);
    return AuthSuccessModel.fromJson(response.data);
  }

  /// Disable 2FA (requires auth + password)
  /// POST /auth/disable-2fa { password }
  Future<AuthSuccessModel> disable2FA({required String password}) async {
    final response = await _api.post(
      ApiEndpoints.authDisable2FA,
      data: {'password': password},
    );
    _checkResponse(response);
    return AuthSuccessModel.fromJson(response.data);
  }

  /// Change password (requires auth)
  /// POST /auth/change-password { currentPassword, newPassword, confirmNewPassword }
  Future<AuthSuccessModel> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await _api.post(
      ApiEndpoints.authChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
    _checkResponse(response);
    return AuthSuccessModel.fromJson(response.data);
  }

  /// Refresh tokens
  /// POST /auth/refresh { refreshToken }
  Future<AuthTokensModel> refreshTokens(String refreshToken) async {
    final response = await _api.post(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
      options: Options(
        extra: {
          '__skipRefresh': true,
          '__skipAuth': true,
        },
      ),
    );
    
    _checkResponse(response);
    return AuthTokensModel.fromJson(response.data);
  }

  /// Logout
  /// POST /auth/logout { refreshToken }
  Future<void> logout() async {
    try {
      final storage = Get.find<StorageService>();
      final refreshToken = storage.refreshToken;
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      // Ignore logout errors, we'll clear local state anyway
    }
  }

  /// Check response and throw if error
  void _checkResponse(Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _extractErrorMessage(response.data),
      );
    }
    
    // Also check for success: false in body
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: _extractErrorMessage(data),
      );
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['error'] is Map<String, dynamic>) {
        return data['error']['message'] as String? ?? 'Có lỗi xảy ra';
      }
      return data['message'] as String? ?? 'Có lỗi xảy ra';
    }
    return 'Có lỗi xảy ra';
  }
}

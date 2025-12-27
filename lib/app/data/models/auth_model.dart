import 'user_model.dart';

/// Auth tokens response
/// 
/// Backend response format:
/// { success: true, data: { accessToken, refreshToken, user? } }
class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
  final UserModel? user;

  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.user,
  });

  /// Parse from backend response
  /// Handles both wrapped format { data: { ... } } and direct format
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    // Check if response has data wrapper
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    return AuthTokensModel(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: data['expiresIn'] as int?,
      user: data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'user': user?.toJson(),
    };
  }
}

/// Login response - can return tokens OR requires 2FA
class LoginResponseModel {
  final bool success;
  final bool requires2FA;
  final String? userId; // For 2FA verification
  final String? message;
  final AuthTokensModel? tokens;

  LoginResponseModel({
    required this.success,
    this.requires2FA = false,
    this.userId,
    this.message,
    this.tokens,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    // Check if 2FA is required
    if (data != null && data['requires2FA'] == true) {
      return LoginResponseModel(
        success: json['success'] as bool? ?? true,
        requires2FA: true,
        userId: data['userId'] as String?,
        message: data['message'] as String?,
      );
    }
    
    // Normal login - tokens returned
    return LoginResponseModel(
      success: json['success'] as bool? ?? true,
      requires2FA: false,
      tokens: data != null ? AuthTokensModel.fromJson(json) : null,
    );
  }
}

/// Register response
class RegisterResponseModel {
  final bool success;
  final String? message;
  final AuthTokensModel? tokens;

  RegisterResponseModel({
    required this.success,
    this.message,
    this.tokens,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      tokens: json['data'] != null ? AuthTokensModel.fromJson(json) : null,
    );
  }
}

/// 2FA verification response
class Verify2FAResponseModel {
  final bool success;
  final String? message;
  final AuthTokensModel? tokens;

  Verify2FAResponseModel({
    required this.success,
    this.message,
    this.tokens,
  });

  factory Verify2FAResponseModel.fromJson(Map<String, dynamic> json) {
    return Verify2FAResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      tokens: json['data'] != null ? AuthTokensModel.fromJson(json) : null,
    );
  }
}

/// Simple success response
class AuthSuccessModel {
  final bool success;
  final String? message;

  AuthSuccessModel({
    required this.success,
    this.message,
  });

  factory AuthSuccessModel.fromJson(Map<String, dynamic> json) {
    return AuthSuccessModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }
}

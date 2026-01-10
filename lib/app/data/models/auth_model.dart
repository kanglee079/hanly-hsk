import 'user_model.dart';

/// Anonymous user response
/// POST /auth/anonymous
class AnonymousUserResponseModel {
  final bool success;
  final String userId;
  final String accessToken;
  final String refreshToken;
  final bool isAnonymous;
  final bool isNewUser; // true = new device, false = returning user
  final DateTime createdAt;

  AnonymousUserResponseModel({
    required this.success,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.isAnonymous,
    required this.isNewUser,
    required this.createdAt,
  });

  factory AnonymousUserResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AnonymousUserResponseModel(
      success: json['success'] as bool? ?? true,
      userId: data['userId'] as String,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      isNewUser: data['isNewUser'] as bool? ?? true,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}

/// Auth status response
/// GET /auth/status
class AuthStatusResponseModel {
  final bool success;
  final String userId;
  final bool isAnonymous;
  final bool hasEmail;
  final String? email;
  final String? displayName;
  final DateTime createdAt;

  AuthStatusResponseModel({
    required this.success,
    required this.userId,
    required this.isAnonymous,
    required this.hasEmail,
    this.email,
    this.displayName,
    required this.createdAt,
  });

  factory AuthStatusResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthStatusResponseModel(
      success: json['success'] as bool? ?? true,
      userId: data['userId'] as String,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      hasEmail: data['hasEmail'] as bool? ?? false,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}

/// Link account request response
/// POST /auth/link-account
class LinkAccountResponseModel {
  final bool success;
  final String linkId;
  final DateTime expiresAt;
  final String message;

  LinkAccountResponseModel({
    required this.success,
    required this.linkId,
    required this.expiresAt,
    required this.message,
  });

  factory LinkAccountResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return LinkAccountResponseModel(
      success: json['success'] as bool? ?? true,
      linkId: data['linkId'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
      message: data['message'] as String? ?? 'Đã gửi email xác nhận',
    );
  }
}

/// Verify link account response
/// POST /auth/verify-link-account
class VerifyLinkAccountResponseModel {
  final bool success;
  final String userId;
  final String email;
  final bool isAnonymous;
  final String accessToken;
  final String refreshToken;
  final bool merged;
  final MergeResultModel? mergeResult;

  VerifyLinkAccountResponseModel({
    required this.success,
    required this.userId,
    required this.email,
    required this.isAnonymous,
    required this.accessToken,
    required this.refreshToken,
    required this.merged,
    this.mergeResult,
  });

  factory VerifyLinkAccountResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return VerifyLinkAccountResponseModel(
      success: json['success'] as bool? ?? true,
      userId: data['userId'] as String,
      email: data['email'] as String,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      merged: data['merged'] as bool? ?? false,
      mergeResult: data['mergeResult'] != null
          ? MergeResultModel.fromJson(data['mergeResult'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Merge result when linking existing account
class MergeResultModel {
  final int vocabsLearned;
  final int streakDays;
  final String? message;

  MergeResultModel({
    required this.vocabsLearned,
    required this.streakDays,
    this.message,
  });

  factory MergeResultModel.fromJson(Map<String, dynamic> json) {
    return MergeResultModel(
      vocabsLearned: json['vocabsLearned'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// Auth tokens response
/// 
/// Backend response format:
/// { success: true, data: { accessToken, refreshToken, user? } }
class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
  final UserModel? user;
  final bool? isAnonymous;

  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.user,
    this.isAnonymous,
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
      isAnonymous: data['isAnonymous'] as bool?,
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

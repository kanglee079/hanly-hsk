import 'package:get/get.dart';
import '../data/models/auth_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repo.dart';
import '../data/repositories/me_repo.dart';
import '../core/utils/logger.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';
import 'realtime/realtime_sync_service.dart';

/// Auth session service - Email + Password + 2FA
class AuthSessionService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  late final AuthRepo _authRepo;
  late final MeRepo _meRepo;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  
  /// Pending 2FA userId (when login returns requires2FA: true)
  final RxString pending2FAUserId = ''.obs;
  final RxString pending2FAEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _authRepo = Get.find<AuthRepo>();
    _meRepo = Get.find<MeRepo>();
    currentUser.value = _storage.user;
  }

  /// Get access token
  String? get accessToken => _storage.accessToken;

  /// Get refresh token
  String? get refreshToken => _storage.refreshToken;

  /// Check if logged in
  bool get isLoggedIn => _storage.isLoggedIn;
  
  /// Check if has pending 2FA
  bool get hasPending2FA => pending2FAUserId.value.isNotEmpty;

  /// Set tokens
  void setTokens(String accessToken, String refreshToken) {
    _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Clear session - clears all user-specific data
  void clearSession() {
    _storage.clearAuth();
    currentUser.value = null;
    pending2FAUserId.value = '';
    pending2FAEmail.value = '';
    
    // Clear realtime sync cached data
    if (Get.isRegistered<RealtimeSyncService>()) {
      Get.find<RealtimeSyncService>().clearAllCachedData();
    }
  }

  /// Register with email + password
  Future<RegisterResponseModel?> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      isLoading.value = true;
      
      final response = await _authRepo.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      if (response.success && response.tokens != null) {
        await _handleAuthSuccess(response.tokens!);
      }
      
      Logger.d('AuthSessionService', 'Register successful for $email');
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'register error', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email + password
  /// Returns LoginResponseModel which may require 2FA
  Future<LoginResponseModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      _storage.lastEmail = email;
      
      final response = await _authRepo.login(
        email: email,
        password: password,
      );
      
      if (response.requires2FA) {
        // Store pending 2FA info
        pending2FAUserId.value = response.userId ?? '';
        pending2FAEmail.value = email;
        Logger.d('AuthSessionService', '2FA required for $email');
      } else if (response.tokens != null) {
        // Login successful without 2FA
        await _handleAuthSuccess(response.tokens!);
        Logger.d('AuthSessionService', 'Login successful for $email');
      }
      
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'login error', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify 2FA code
  Future<Verify2FAResponseModel?> verify2FA(String code) async {
    if (pending2FAUserId.value.isEmpty) {
      Logger.e('AuthSessionService', 'No pending 2FA userId');
      return null;
    }
    
    try {
      isLoading.value = true;
      
      final response = await _authRepo.verify2FA(
        userId: pending2FAUserId.value,
        code: code,
      );
      
      if (response.success && response.tokens != null) {
        await _handleAuthSuccess(response.tokens!);
        pending2FAUserId.value = '';
        pending2FAEmail.value = '';
        Logger.d('AuthSessionService', '2FA verified successfully');
      }
      
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'verify2FA error', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend 2FA code
  Future<bool> resend2FA() async {
    if (pending2FAUserId.value.isEmpty) {
      Logger.e('AuthSessionService', 'No pending 2FA userId');
      return false;
    }
    
    try {
      isLoading.value = true;
      
      final response = await _authRepo.resend2FA(
        userId: pending2FAUserId.value,
      );
      
      Logger.d('AuthSessionService', 'Resend 2FA: ${response.message}');
      return response.success;
    } catch (e) {
      Logger.e('AuthSessionService', 'resend2FA error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Enable 2FA for current user
  Future<bool> enable2FA() async {
    try {
      isLoading.value = true;
      final response = await _authRepo.enable2FA();
      
      if (response.success) {
        // Update local user
        if (currentUser.value != null) {
          currentUser.value = currentUser.value!.copyWith(
            twoFactorEnabled: true,
          );
          _storage.user = currentUser.value;
        }
      }
      
      return response.success;
    } catch (e) {
      Logger.e('AuthSessionService', 'enable2FA error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Disable 2FA (requires password)
  Future<bool> disable2FA(String password) async {
    try {
      isLoading.value = true;
      final response = await _authRepo.disable2FA(password: password);
      
      if (response.success) {
        // Update local user
        if (currentUser.value != null) {
          currentUser.value = currentUser.value!.copyWith(
            twoFactorEnabled: false,
          );
          _storage.user = currentUser.value;
        }
      }
      
      return response.success;
    } catch (e) {
      Logger.e('AuthSessionService', 'disable2FA error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      isLoading.value = true;
      final response = await _authRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      
      return response.success;
    } catch (e) {
      Logger.e('AuthSessionService', 'changePassword error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle successful auth (save tokens, fetch user)
  Future<void> _handleAuthSuccess(AuthTokensModel tokens) async {
    _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    if (tokens.user != null) {
      _storage.user = tokens.user;
      currentUser.value = tokens.user;
    } else {
      await fetchCurrentUser();
    }
  }

  /// Refresh tokens (called by RefreshInterceptor or manually)
  Future<bool> refreshTokens() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      Logger.w('AuthSessionService', 'No refresh token available');
      return false;
    }

    try {
      final response = await _authRepo.refreshTokens(refreshToken);

      _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      if (response.user != null) {
        _storage.user = response.user;
        currentUser.value = response.user;
      }

      Logger.d('AuthSessionService', 'Tokens refreshed successfully');
      return true;
    } catch (e) {
      Logger.e('AuthSessionService', 'refreshTokens error', e);
      return false;
    }
  }

  /// Fetch current user
  Future<UserModel?> fetchCurrentUser() async {
    try {
      final user = await _meRepo.getMe();
      _storage.user = user;
      currentUser.value = user;
      return user;
    } catch (e) {
      Logger.e('AuthSessionService', 'fetchCurrentUser error', e);
      return null;
    }
  }

  /// Submit onboarding data
  Future<bool> submitOnboarding({
    required String displayName,
    required String goalType,
    required String currentLevel,
    required int dailyMinutesTarget,
    required int dailyNewLimit,
    required Map<String, double> focusWeights,
    bool notificationsEnabled = false,
    String? reminderTime,
  }) async {
    try {
      isLoading.value = true;
      final profile = await _meRepo.submitOnboarding(
        displayName: displayName,
        goalType: goalType,
        currentLevel: currentLevel,
        dailyMinutesTarget: dailyMinutesTarget,
        dailyNewLimit: dailyNewLimit,
        focusWeights: focusWeights,
        notificationsEnabled: notificationsEnabled,
        reminderTime: reminderTime,
      );

      // Update local user with new profile
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          displayName: displayName,
          profile: profile,
        );
        _storage.user = currentUser.value;
      }
      
      _storage.isOnboardingComplete = true;
      Logger.d('AuthSessionService', 'Onboarding submitted successfully');
      return true;
    } catch (e) {
      Logger.e('AuthSessionService', 'submitOnboarding error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update profile (partial update)
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      isLoading.value = true;
      final profile = await _meRepo.updateProfile(profileData);

      // Update local user with new profile
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(profile: profile);
        _storage.user = currentUser.value;
      }
      
      return true;
    } catch (e) {
      Logger.e('AuthSessionService', 'updateProfile error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authRepo.logout();
    } catch (e) {
      Logger.w('AuthSessionService', 'logout API error: $e');
    } finally {
      clearSession();
      Get.offAllNamed(Routes.auth);
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      isLoading.value = true;
      await _meRepo.deleteAccount();
      clearSession();
      Get.offAllNamed(Routes.auth);
      return true;
    } catch (e) {
      Logger.e('AuthSessionService', 'deleteAccount error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if user needs onboarding
  bool get needsOnboarding {
    final user = currentUser.value;
    return user != null && !user.hasProfile && !_storage.isOnboardingComplete;
  }
}

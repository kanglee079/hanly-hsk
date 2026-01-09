import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../data/models/auth_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repo.dart';
import '../data/repositories/me_repo.dart';
import '../core/utils/logger.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';
import 'realtime/realtime_sync_service.dart';

/// Auth session service - Anonymous-First + Email + Password + 2FA
class AuthSessionService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  late final AuthRepo _authRepo;
  late final MeRepo _meRepo;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  
  /// Is current user anonymous (not linked email)
  final RxBool isAnonymous = true.obs;
  
  /// Pending 2FA userId (when login returns requires2FA: true)
  final RxString pending2FAUserId = ''.obs;
  final RxString pending2FAEmail = ''.obs;
  
  /// Pending link account info
  final RxString pendingLinkId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _authRepo = Get.find<AuthRepo>();
    _meRepo = Get.find<MeRepo>();
    currentUser.value = _storage.user;
    isAnonymous.value = _storage.isAnonymous;
  }

  /// Get access token
  String? get accessToken => _storage.accessToken;

  /// Get refresh token
  String? get refreshToken => _storage.refreshToken;

  /// Check if logged in (has valid tokens)
  bool get isLoggedIn => _storage.isLoggedIn;
  
  /// Check if setup completed (name, level, goals)
  bool get isSetupComplete => _storage.isSetupComplete;
  
  /// Check if intro seen
  bool get isIntroSeen => _storage.isIntroSeen;
  
  /// Check if has pending 2FA
  bool get hasPending2FA => pending2FAUserId.value.isNotEmpty;
  
  /// Get or create device ID (persisted in storage)
  String getDeviceId() {
    String? deviceId = _storage.deviceId;
    
    if (deviceId == null || deviceId.isEmpty) {
      // Generate a simple unique ID using timestamp and random
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      _storage.deviceId = deviceId;
    }
    
    return deviceId;
  }
  
  /// Get device info for anonymous user creation
  Map<String, dynamic> getDeviceInfo() {
    String platform = 'unknown';
    
    if (Platform.isIOS) {
      platform = 'ios';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isMacOS) {
      platform = 'macos';
    }
    
    return {
      'platform': platform,
      'osVersion': Platform.operatingSystemVersion,
      'appVersion': '2.0.0',
      'model': platform,
    };
  }

  /// Create anonymous user on first launch
  /// If device already has an account (DUPLICATE_ERROR), try to recover session
  Future<bool> createAnonymousUser() async {
    try {
      isLoading.value = true;
      
      final deviceId = getDeviceId();
      final deviceInfo = getDeviceInfo();
      
      final response = await _authRepo.createAnonymousUser(
        deviceId: deviceId,
        deviceInfo: deviceInfo,
      );
      
      if (response.success) {
        _storage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _storage.isAnonymous = true;
        isAnonymous.value = true;
        
        Logger.d('AuthSessionService', 'Anonymous user created: ${response.userId}');
        return true;
      }
      
      return false;
    } catch (e) {
      // Check if this is a DUPLICATE_ERROR - device already has an account
      if (_isDuplicateError(e)) {
        Logger.d('AuthSessionService', 'Device already has account, trying to recover session');
        return await _recoverExistingSession();
      }
      
      Logger.e('AuthSessionService', 'createAnonymousUser error', e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Check if the error is a duplicate device error
  bool _isDuplicateError(dynamic error) {
    if (error is DioException) {
      final message = error.message ?? '';
      final response = error.response?.data;
      
      // Check error message
      if (message.contains('Duplicate') || message.contains('DUPLICATE')) {
        return true;
      }
      
      // Check response data
      if (response is Map<String, dynamic>) {
        final errorCode = response['error']?['code'];
        if (errorCode == 'DUPLICATE_ERROR' || errorCode == 'DEVICE_EXISTS') {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Try to recover an existing session for this device
  /// This is called when the device already has an account but no tokens
  Future<bool> _recoverExistingSession() async {
    try {
      // First, check if we already have valid tokens
      final existingToken = _storage.accessToken;
      if (existingToken != null && existingToken.isNotEmpty) {
        // Try to validate the existing token
        final status = await getAuthStatus();
        if (status != null) {
          Logger.d('AuthSessionService', 'Recovered session using existing tokens');
          return true;
        }
      }
      
      // Try to refresh using stored refresh token
      final refreshToken = _storage.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final tokens = await _authRepo.refreshTokens(refreshToken);
          _storage.saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          );
          _storage.isAnonymous = true;
          isAnonymous.value = true;
          Logger.d('AuthSessionService', 'Recovered session using refresh token');
          return true;
        } catch (e) {
          Logger.e('AuthSessionService', 'Failed to refresh existing session', e);
        }
      }
      
      // If we can't recover, we need to login with device ID
      // Try calling login-device endpoint if available
      try {
        final deviceId = getDeviceId();
        final deviceInfo = getDeviceInfo();
        final response = await _authRepo.loginWithDevice(
          deviceId: deviceId,
          deviceInfo: deviceInfo,
        );
        
        if (response.success) {
          _storage.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
          _storage.isAnonymous = true;
          isAnonymous.value = true;
          Logger.d('AuthSessionService', 'Recovered session via device login');
          return true;
        }
      } catch (e) {
        Logger.e('AuthSessionService', 'Device login failed', e);
      }
      
      // Last resort: Generate new device ID and create fresh account
      Logger.w('AuthSessionService', 'Could not recover session, creating new device identity');
      _storage.deviceId = null; // Clear old device ID
      
      // Retry with new device ID
      final newDeviceId = getDeviceId(); // This will generate a new one
      final deviceInfo = getDeviceInfo();
      
      final response = await _authRepo.createAnonymousUser(
        deviceId: newDeviceId,
        deviceInfo: deviceInfo,
      );
      
      if (response.success) {
        _storage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _storage.isAnonymous = true;
        isAnonymous.value = true;
        Logger.d('AuthSessionService', 'Created new anonymous user with new device ID');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.e('AuthSessionService', 'Failed to recover existing session', e);
      return false;
    }
  }
  
  /// Get auth status from server
  Future<AuthStatusResponseModel?> getAuthStatus() async {
    try {
      final response = await _authRepo.getAuthStatus();
      isAnonymous.value = response.isAnonymous;
      _storage.isAnonymous = response.isAnonymous;
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'getAuthStatus error', e);
      return null;
    }
  }
  
  /// Request account link (send verification email)
  Future<LinkAccountResponseModel?> requestLinkAccount(String email) async {
    try {
      isLoading.value = true;
      
      final response = await _authRepo.linkAccount(email: email);
      
      if (response.success) {
        pendingLinkId.value = response.linkId;
        Logger.d('AuthSessionService', 'Link request sent to $email');
      }
      
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'requestLinkAccount error', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Verify link account token
  Future<VerifyLinkAccountResponseModel?> verifyLinkAccount({
    required String linkId,
    required String token,
  }) async {
    try {
      isLoading.value = true;
      
      final response = await _authRepo.verifyLinkAccount(
        linkId: linkId,
        token: token,
      );
      
      if (response.success) {
        _storage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _storage.isAnonymous = false;
        isAnonymous.value = false;
        pendingLinkId.value = '';
        
        // Fetch updated user
        await fetchCurrentUser();
        
        Logger.d('AuthSessionService', 'Account linked successfully: ${response.email}');
      }
      
      return response;
    } catch (e) {
      Logger.e('AuthSessionService', 'verifyLinkAccount error', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Mark intro as seen
  void markIntroSeen() {
    _storage.isIntroSeen = true;
  }
  
  /// Mark setup as complete
  void markSetupComplete() {
    _storage.isSetupComplete = true;
  }

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

  /// Logout - clears session but keeps device ID
  /// User will become anonymous again
  Future<void> logout() async {
    try {
      await _authRepo.logout();
    } catch (e) {
      Logger.w('AuthSessionService', 'logout API error: $e');
    } finally {
      clearSession();
      // Re-create anonymous user
      await createAnonymousUser();
      Get.offAllNamed(Routes.shell);
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      isLoading.value = true;
      await _meRepo.deleteAccount();
      clearSession();
      // Navigate to intro for fresh start
      Get.offAllNamed(Routes.intro);
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

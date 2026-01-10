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
  
  /// Is this a new user (first time on this device) or returning user
  final RxBool isNewUser = true.obs;
  
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

  /// Create or login anonymous user
  /// - If device already has an account → auto login to that account (isNewUser: false)
  /// - If new device → create new anonymous account (isNewUser: true)
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
        _storage.isAnonymous = response.isAnonymous;
        isAnonymous.value = response.isAnonymous;
        isNewUser.value = response.isNewUser;
        
        // If returning user, mark intro/setup as complete (they already did it before)
        if (!response.isNewUser) {
          Logger.d('AuthSessionService', 'Returning user detected - skipping intro/setup');
          _storage.isIntroSeen = true;
          _storage.isSetupComplete = true;
          _storage.isOnboardingComplete = true;
        }
        
        Logger.d('AuthSessionService', 
          'Auth success: userId=${response.userId}, isNewUser=${response.isNewUser}, isAnonymous=${response.isAnonymous}');
        return true;
      }
      
      return false;
    } catch (e) {
      // Check if this is a DUPLICATE_ERROR - shouldn't happen after BE fix, but keep as fallback
      if (_isDuplicateError(e)) {
        Logger.d('AuthSessionService', 'Device already registered, trying fallback login');
        return await _loginWithExistingDevice();
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
  
  /// Login with existing device ID (auto-login to previous account)
  /// Called when device already has an account registered (DUPLICATE_ERROR)
  /// 
  /// Expected behavior after BE fix:
  /// - POST /auth/anonymous should return tokens for existing device
  /// - This fallback should not be needed once BE is fixed
  Future<bool> _loginWithExistingDevice() async {
    try {
      // Priority 1: Check if we have valid tokens stored
      final existingToken = _storage.accessToken;
      if (existingToken != null && existingToken.isNotEmpty) {
        final status = await getAuthStatus();
        if (status != null) {
          Logger.d('AuthSessionService', '✅ Auto-login using existing tokens');
          _storage.isIntroSeen = true;
          _storage.isSetupComplete = true;
          return true;
        }
      }
      
      // Priority 2: Try refresh token
      final refreshToken = _storage.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final tokens = await _authRepo.refreshTokens(refreshToken);
          _storage.saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          );
          _storage.isAnonymous = tokens.isAnonymous ?? true;
          isAnonymous.value = tokens.isAnonymous ?? true;
          _storage.isIntroSeen = true;
          _storage.isSetupComplete = true;
          Logger.d('AuthSessionService', '✅ Auto-login via refresh token');
          return true;
        } catch (e) {
          Logger.w('AuthSessionService', '⚠️ Refresh token expired or invalid');
        }
      }
      
      // Priority 3: Call device-login endpoint (if BE has it)
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
          _storage.isAnonymous = response.isAnonymous;
          isAnonymous.value = response.isAnonymous;
          _storage.isIntroSeen = true;
          _storage.isSetupComplete = true;
          Logger.d('AuthSessionService', '✅ Auto-login via device-login endpoint');
          return true;
        }
      } catch (e) {
        // Endpoint might not exist yet - this is expected
        Logger.w('AuthSessionService', '⚠️ device-login endpoint not available: $e');
      }
      
      // If all recovery fails, continue in offline mode
      // DO NOT reset device ID (resetting causes more DUPLICATE_ERROR)
      Logger.w('AuthSessionService', 
        '⚠️ Cannot recover account - BE cần fix /auth/anonymous để trả token cho device đã tồn tại');
      
      // Enable offline mode so app still works
      _continueOfflineMode();
      
      return false;
    } catch (e) {
      Logger.e('AuthSessionService', 'Auto-login failed', e);
      _continueOfflineMode();
      return false;
    }
  }
  
  /// Continue in offline mode when auth fails
  /// App will function without server sync
  void _continueOfflineMode() {
    Logger.d('AuthSessionService', '📴 Continuing in offline mode');
    _storage.isAnonymous = true;
    isAnonymous.value = true;
    isOfflineMode.value = true;
    
    // Still allow user to go through intro/setup
    // This provides the best UX even when server is having issues
  }
  
  /// Is the app running in offline mode (no server auth)
  final RxBool isOfflineMode = false.obs;
  
  /// Retry authentication (user can trigger this manually)
  Future<bool> retryAuthentication() async {
    Logger.d('AuthSessionService', '🔄 Retrying authentication...');
    isOfflineMode.value = false;
    return await createAnonymousUser();
  }
  
  /// Force reset all auth state and try fresh
  /// Call this when user explicitly wants to start over
  /// WARNING: This clears all local data and creates a new account
  Future<bool> forceResetAndCreateAccount() async {
    Logger.d('AuthSessionService', '🔄 Force resetting auth state...');
    
    // Clear everything
    _storage.clearAuth();
    _storage.deviceId = null; // Generate new device ID
    _storage.isAnonymous = true;
    _storage.isSetupComplete = false;
    _storage.isOnboardingComplete = false;
    _storage.isIntroSeen = false;
    isOfflineMode.value = false;
    
    // Try to create fresh account
    return await createAnonymousUser();
  }
  
  /// Check if this device has been registered before
  /// Returns the device ID if exists
  String? get existingDeviceId => _storage.deviceId;
  
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

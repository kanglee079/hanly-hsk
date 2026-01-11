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
  /// 
  /// BE behavior (after fix):
  /// - New device → creates user, returns { isNewUser: true }
  /// - Existing device → returns existing user, { isNewUser: false }
  /// - Deleted user → reactivates, returns { isNewUser: false }
  /// - Suspended user → throws UnauthorizedError
  /// - Race condition → handled gracefully by BE
  Future<bool> createAnonymousUser() async {
    try {
      isLoading.value = true;
      isOfflineMode.value = false;
      
      final deviceId = getDeviceId();
      final deviceInfo = getDeviceInfo();
      
      Logger.d('AuthSessionService', '🔄 Creating/logging in anonymous user...');
      
      final response = await _authRepo.createAnonymousUser(
        deviceId: deviceId,
        deviceInfo: deviceInfo,
      );
      
      if (response.success) {
        // Save tokens
        _storage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _storage.isAnonymous = response.isAnonymous;
        isAnonymous.value = response.isAnonymous;
        isNewUser.value = response.isNewUser;
        
        // If returning user (device already had account), skip intro/setup
        if (!response.isNewUser) {
          Logger.d('AuthSessionService', '✅ Returning user detected - skipping intro/setup');
          _storage.isIntroSeen = true;
          _storage.isSetupComplete = true;
          _storage.isOnboardingComplete = true;
        } else {
          Logger.d('AuthSessionService', '✅ New user created');
        }
        
        Logger.d('AuthSessionService', 
          '✅ Auth success: userId=${response.userId}, isNewUser=${response.isNewUser}, isAnonymous=${response.isAnonymous}');
        return true;
      }
      
      Logger.w('AuthSessionService', '⚠️ Auth response was not successful');
      return false;
    } catch (e) {
      // Handle specific error cases
      if (_isSuspendedError(e)) {
        Logger.e('AuthSessionService', '🚫 Account suspended');
        // TODO: Show suspended account dialog to user
        return false;
      }
      
      if (_isNetworkError(e)) {
        Logger.w('AuthSessionService', '📴 Network error - continuing offline');
        _continueOfflineMode();
        return false;
      }
      
      Logger.e('AuthSessionService', '❌ createAnonymousUser error', e);
      _continueOfflineMode();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Check if error is a suspended account error
  bool _isSuspendedError(dynamic error) {
    if (error is DioException) {
      final response = error.response?.data;
      if (response is Map<String, dynamic>) {
        final message = response['error']?['message'] ?? '';
        if (message.contains('tạm khóa') || message.contains('suspended')) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Check if error is a network error
  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.sendTimeout;
    }
    return false;
  }
  
  /// Continue in offline mode when auth fails
  /// App will function without server sync
  void _continueOfflineMode() {
    Logger.d('AuthSessionService', '📴 Continuing in offline mode');
    _storage.isAnonymous = true;
    isAnonymous.value = true;
    isOfflineMode.value = true;
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
    // Clear previous user's cached data to prevent cross-account data leakage
    // This is important when switching accounts
    try {
      if (Get.isRegistered<RealtimeSyncService>()) {
        Get.find<RealtimeSyncService>().clearAllCachedData();
      }
    } catch (e) {
      Logger.w('AuthSessionService', 'Error clearing cached data: $e');
    }
    
    _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    // Update anonymous flag based on tokens (linked email = not anonymous)
    isAnonymous.value = tokens.isAnonymous ?? false;

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

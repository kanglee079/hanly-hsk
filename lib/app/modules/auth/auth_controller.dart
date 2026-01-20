import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_session_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/hm_toast.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';

/// Auth controller - Email + Password + 2FA
class AuthController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

  // Observables
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxString code = ''.obs;
  
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString codeError = ''.obs;
  
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  bool get isEmailValid => Validators.isValidEmail(email.value);
  bool get isPasswordValid => _validatePassword(password.value) == null;
  bool get isConfirmPasswordValid => confirmPassword.value == password.value;
  bool get isCodeValid => code.value.length == 6;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() => email.value = emailController.text);
    passwordController.addListener(() => password.value = passwordController.text);
    confirmPasswordController.addListener(() => confirmPassword.value = confirmPasswordController.text);
    codeController.addListener(() => code.value = codeController.text);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Validate password strength (simplified - minimum 6 characters)
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Mật khẩu ít nhất 6 ký tự';
    }
    return null;
  }

  /// Login with email + password
  Future<void> login() async {
    emailError.value = '';
    passwordError.value = '';

    if (!isEmailValid) {
      emailError.value = 'Email không hợp lệ';
      return;
    }

    if (password.value.isEmpty) {
      passwordError.value = 'Vui lòng nhập mật khẩu';
      return;
    }

    isLoading.value = true;
    
    try {
      final response = await _authService.login(
        email: email.value.trim(),
        password: password.value,
      );

      if (response != null) {
        if (response.requires2FA) {
          // Navigate to 2FA screen
          Get.toNamed(Routes.authVerify2FA);
        } else {
          // Login successful
          _navigateAfterAuth();
        }
      }
    } catch (e) {
      Logger.e('AuthController', 'login error', e);
      _handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Register with email + password (simplified)
  /// Auto-merges data from anonymous account
  Future<void> register() async {
    emailError.value = '';
    passwordError.value = '';

    if (!isEmailValid) {
      emailError.value = 'Email không hợp lệ';
      return;
    }

    final passwordValidation = _validatePassword(password.value);
    if (passwordValidation != null) {
      passwordError.value = passwordValidation;
      return;
    }

    isLoading.value = true;
    
    try {
      final response = await _authService.register(
        email: email.value.trim(),
        password: password.value,
      );

      if (response != null && response.success) {
        // Show success message with merge info if available
        if (response.merged && response.mergeResult != null) {
          HMToast.success(response.mergeResult!.message ?? 'Đăng ký thành công!');
        } else {
        HMToast.success('Đăng ký thành công!');
        }
        _navigateAfterAuth();
      }
    } catch (e) {
      Logger.e('AuthController', 'register error', e);
      _handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify 2FA code
  Future<void> verify2FA() async {
    codeError.value = '';

    if (!isCodeValid) {
      codeError.value = 'Mã xác thực phải có 6 số';
      return;
    }

    isLoading.value = true;
    
    try {
      final response = await _authService.verify2FA(code.value.trim());

      if (response != null && response.success) {
        HMToast.success('Xác thực thành công!');
        _navigateAfterAuth();
      }
    } catch (e) {
      Logger.e('AuthController', 'verify2FA error', e);
      codeError.value = 'Mã xác thực không đúng hoặc đã hết hạn';
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend 2FA code
  Future<void> resend2FA() async {
    isLoading.value = true;
    
    try {
      final success = await _authService.resend2FA();
      if (success) {
        HMToast.success('Đã gửi lại mã xác thực');
      } else {
        HMToast.error('Không thể gửi lại mã');
      }
    } catch (e) {
      HMToast.error('Có lỗi xảy ra');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to register screen
  void goToRegister() {
    _clearFields();
    Get.toNamed(Routes.authRegister);
  }

  /// Navigate to login screen
  void goToLogin() {
    _clearFields();
    Get.back();
  }

  /// Clear all fields
  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    codeController.clear();
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    codeError.value = '';
  }

  /// Navigate after successful auth
  void _navigateAfterAuth() {
    _clearFields();
    
    if (_authService.needsOnboarding) {
      Get.offAllNamed(Routes.onboarding);
    } else {
      Get.offAllNamed(Routes.shell);
    }
  }

  /// Handle auth errors
  void _handleAuthError(dynamic error) {
    String message = 'Có lỗi xảy ra';
    
    if (error.toString().contains('Email đã tồn tại')) {
      emailError.value = 'Email đã được sử dụng';
      return;
    }
    
    if (error.toString().contains('không đúng') || 
        error.toString().contains('incorrect')) {
      message = 'Email hoặc mật khẩu không đúng';
    } else if (error.toString().contains('khóa') || 
               error.toString().contains('locked')) {
      message = 'Tài khoản tạm khóa. Vui lòng thử lại sau 30 phút';
    } else if (error.toString().contains('password') ||
               error.toString().contains('mật khẩu')) {
      passwordError.value = 'Mật khẩu không đủ mạnh';
      return;
    }
    
    HMToast.error(message);
  }
}

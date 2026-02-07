import 'package:flutter/foundation.dart';
import 'package:gozapper/core/services/notification_service.dart';
import 'package:gozapper/domain/entities/user.dart';
import 'package:gozapper/domain/repositories/auth_repository.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/* Details
FCM token - fdRrtINsQGSiv9q0svbOUH:APA91bE46JwpdXYSN0_yV3Te8ZdRI7NLhdPnFTl-C91men_HeJgTUG3ZqHBziDUMrGyUhVfsgyGXx2FT3SNVxqj_f8rpO3Bs6uzABbqM7F2yHYRLSXKtX1s
user id - 5d41e863-1bae-46d5-8834-cbae990629b7
 */
class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;
  final CredentialProvider? credentialProvider;

  // Optional references to other providers for clearing user data on logout
  dynamic _deliveryProvider;
  dynamic _paymentMethodProvider;

  AuthProvider({
    required this.authRepository,
    this.credentialProvider,
  });

  // Setters for other providers (injected after initialization to avoid circular dependencies)
  void setDeliveryProvider(dynamic deliveryProvider) {
    _deliveryProvider = deliveryProvider;
  }

  void setPaymentMethodProvider(dynamic paymentMethodProvider) {
    _paymentMethodProvider = paymentMethodProvider;
  }

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    _setLoading(true);

    final result = await authRepository.isLoggedIn();

    result.fold(
      (failure) {
        _setStatus(AuthStatus.unauthenticated);
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          final userResult = await authRepository.getCurrentUser();
          userResult.fold(
            (failure) {
              _setStatus(AuthStatus.unauthenticated);
            },
            (user) async {
              _user = user;
              debugPrint("general log: userid is ${user?.id}");
              _setStatus(AuthStatus.authenticated);
              // Load active credential after successful initialization
              await credentialProvider?.fetchActiveCredential();
              // Send device token to backend for push notifications
              NotificationService().sendDeviceTokenToBackend();
            },
          );
        } else {
          _setStatus(AuthStatus.unauthenticated);
        }
      },
    );

    _setLoading(false);
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(AuthStatus.error);
      },
      (user) async {
        print("General log: the user is $user");
        // Don't set as authenticated if email is not verified
        if (user.emailVerified) {
          _user = user;
          _setStatus(AuthStatus.authenticated);
          // Load active credential after successful registration (if email verified)
          await credentialProvider?.fetchActiveCredential();
        } else {
          _setStatus(AuthStatus.unauthenticated);
        }
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.login(
      email: email,
      password: password,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(AuthStatus.error);
      },
      (user) async {
        _user = user;
        _setStatus(AuthStatus.authenticated);
        success = true;
        // Load active credential after successful login
        await credentialProvider?.fetchActiveCredential();
        // Send device token to backend for push notifications
        NotificationService().sendDeviceTokenToBackend();
      },
    );

    _setLoading(false);
    return success;
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.verifyOtp(
      email: email,
      otp: otp,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (verified) {
        success = verified;
      },
    );

    _setLoading(false);
    return success;
  }

  // Resend OTP
  Future<bool> resendOtp({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.resendOtp(email: email);

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (sent) {
        success = sent;
      },
    );

    _setLoading(false);
    return success;
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    final result = await authRepository.logout();

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (_) {
        clearSession();
      },
    );

    _setLoading(false);
  }

  // Refresh profile
  Future<bool> refreshProfile() async {
    _clearError();

    final result = await authRepository.getProfile();

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (user) {
        _user = user;
        notifyListeners();
        success = true;
      },
    );

    return success;
  }

  // Update profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (user) {
        _user = user;
        notifyListeners();
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Export profile data
  Future<Map<String, dynamic>?> exportProfile() async {
    _clearError();

    final result = await authRepository.exportProfile();

    Map<String, dynamic>? data;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (exportedData) {
        data = exportedData;
      },
    );

    return data;
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.deleteAccount();

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (_) {
        clearSession();
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  void clearSession() {
    // Clear user data from all providers
    _user = null;
    _setStatus(AuthStatus.unauthenticated);

    // Clear credential provider data
    credentialProvider?.clearUserData();

    // Clear delivery provider data
    if (_deliveryProvider != null) {
      _deliveryProvider.clearUserData();
    }

    // Clear payment method provider data
    if (_paymentMethodProvider != null) {
      _paymentMethodProvider.clearUserData();
    }

    notifyListeners();
  }

  // Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (message) {
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Forgot Password
  Future<bool> forgotPassword({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.forgotPassword(
      email: email,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (message) {
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Reset Password
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await authRepository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    bool success = false;

    result.fold(
      (failure) {
        _setError(failure.message);
      },
      (message) {
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Helper methods
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Handle session expiration (called by ApiClient when tokens are cleared)
  void handleSessionExpired() {
    clearSession();
    debugPrint('🔴 Session expired - user logged out and all data cleared');
  }
}

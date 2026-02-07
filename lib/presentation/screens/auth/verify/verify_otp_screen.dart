import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../../widgets/custom_app_bar.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String? password;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.password,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  int _resendCountdown = AppConstants.otpResendDelay;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = AppConstants.otpResendDelay;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != AppConstants.otpLength) {
      SnackBarUtils.showError(
        context,
        'Please enter the complete ${AppConstants.otpLength}-digit code',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.verifyOtp(
      email: widget.email,
      otp: _otpController.text,
    );

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'Email verified successfully!');

      // Auto-login after successful verification if password is available
      if (widget.password != null) {
        final loginSuccess = await authProvider.login(
          email: widget.email,
          password: widget.password!,
        );

        if (!mounted) return;

        if (loginSuccess) {
          SnackBarUtils.showSuccess(context, 'Welcome to GoZapper!');
          context.go(AppRoutes.home);
        } else {
          // Login failed after verification, redirect to login screen
          SnackBarUtils.showError(
            context,
            'Please login to continue',
          );
          context.go(AppRoutes.login);
        }
      } else {
        // No password provided, just go to login screen
        context.go(AppRoutes.login);
      }
    } else {
      SnackBarUtils.showError(
        context,
        authProvider.errorMessage ?? 'Verification failed',
      );
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resendOtp(email: widget.email);

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'OTP resent successfully!');
      _startResendTimer();
    } else {
      SnackBarUtils.showError(
        context,
        authProvider.errorMessage ?? 'Failed to resend OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: "Verify Email",
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
              const Text(
                'Enter the code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle with email
              Text(
                'We sent a verification code to\n${widget.email}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // PIN input
              PinCodeTextField(
                appContext: context,
                length: AppConstants.otpLength,
                controller: _otpController,
                readOnly: true,
                enablePinAutofill: false,
                showCursor: true,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.white,
                  inactiveFillColor: AppColors.white,
                  selectedFillColor: AppColors.white,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  selectedColor: AppColors.primary,
                ),
                animationDuration: const Duration(milliseconds: 200),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                onCompleted: (code) {
                  _verifyOtp();
                },
                onChanged: (value) {},
              ),

              const SizedBox(height: 24),

              // Resend code
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        child: const Text('Resend Code'),
                      )
                    : Text(
                        'Resend code in $_resendCountdown seconds',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
              ),

              const Spacer(),

              // Numeric keypad (custom)
              _buildNumericKeypad(),

              const SizedBox(height: 24),

              // Verify button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _verifyOtp,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildKeypadRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const Expanded(child: SizedBox());
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () {
                if (key == 'delete') {
                  if (_otpController.text.isNotEmpty) {
                    _otpController.text = _otpController.text
                        .substring(0, _otpController.text.length - 1);
                  }
                } else {
                  if (_otpController.text.length < AppConstants.otpLength) {
                    _otpController.text += key;
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: key == 'delete'
                      ? const Icon(Icons.backspace_outlined,
                          color: AppColors.textPrimary)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }
}

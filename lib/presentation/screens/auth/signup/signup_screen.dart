import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:ui' as ui;

import '../../../widgets/custom_app_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String _phoneNumber = '';
  String _countryCode = '';
  String? _initialCountryCode;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _detectCountryCode();
  }

  void _detectCountryCode() {
    // Get country code from device locale
    final locale = ui.PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode;

    setState(() {
      // Use device's country code if available, otherwise default to US
      _initialCountryCode =
          countryCode?.isNotEmpty == true ? countryCode : 'US';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Password validation helpers
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  Future<void> _signup() async {
    context.hideKeyboard();
    if (_emailController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your email');
      return;
    }

    if (!_emailController.text.contains('@')) {
      SnackBarUtils.showError(context, 'Please enter a valid email');
      return;
    }

    if (_firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your first name');
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your last name');
      return;
    }

    if (_phoneNumber.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your phone number');
      return;
    }

    if (_passwordController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a password');
      return;
    }

    if (!_hasMinLength || !_hasNumber || !_hasSpecialChar) {
      SnackBarUtils.showError(context, 'Password does not meet requirements');
      return;
    }

    if (!_agreeToTerms) {
      SnackBarUtils.showError(
          context, 'Please agree to the terms and conditions');
      return;
    }

    // Call the registration API
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumber,
    );

    if (!mounted) return;

    if (success) {
      // Registration successful, navigate to OTP verification
      SnackBarUtils.showSuccess(
        context,
        'Account created! Check your email for verification code',
      );
      // Pass both email and password for auto-login after OTP verification
      context.go(AppRoutes.verifyOtp, extra: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
    } else {
      // Registration failed, show error
      SnackBarUtils.showError(
        context,
        authProvider.errorMessage!.contains("already exists")
            ? "Email already exists"
            : authProvider.errorMessage ?? 'Registration failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: GestureDetector(
          onTap: context.hideKeyboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(text: 'Let\'s get you '),
                      TextSpan(
                        text: 'zapping!',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // First Name
                // const Text(
                //   'First Name',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your first name',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Last Name
                // const Text(
                //   'Last Name',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your last name',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Email
                // const Text(
                //   'Email',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Number
                if (_initialCountryCode != null)
                  IntlPhoneField(
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      counterText: '',
                    ),
                    initialCountryCode: _initialCountryCode,
                    onChanged: (phone) {
                      setState(() {
                        _phoneNumber = phone.completeNumber;
                        _countryCode = phone.countryCode;
                      });
                    },
                  )
                else
                  // Show loading placeholder while detecting country
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Password
                // const Text(
                //   'Password',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    setState(
                        () {}); // Trigger rebuild for validation indicators
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Password validation indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ValidationIndicator(
                      text: 'Min. 8 characters',
                      isValid: _hasMinLength,
                    ),
                    const SizedBox(width: 16),
                    _ValidationIndicator(
                      text: 'At least 1 number',
                      isValid: _hasNumber,
                    ),
                    const SizedBox(width: 16),
                    _ValidationIndicator(
                      text: 'Special char.',
                      isValid: _hasSpecialChar,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(
                                    text: 'By continuing, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final uri = Uri.parse(
                                          'https://yourwebsite.com/terms');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final uri = Uri.parse(
                                          'https://yourwebsite.com/privacy');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          )),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      // height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Sign Up & Zapp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Login link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'I\'m Already a Zapper  ',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.goNextScreen(AppRoutes.login);
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                // const Row(
                //   children: [
                //     Expanded(child: Divider(color: AppColors.border)),
                //     Padding(
                //       padding: EdgeInsets.symmetric(horizontal: 16),
                //       child: Text(
                //         'Or',
                //         style: TextStyle(
                //           color: AppColors.textSecondary,
                //           fontSize: 14,
                //         ),
                //       ),
                //     ),
                //     Expanded(child: Divider(color: AppColors.border)),
                //   ],
                // ),
                //
                // const SizedBox(height: 24),
                //
                // // Continue with Google
                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: OutlinedButton(
                //     onPressed: () {
                //       SnackBarUtils.showInfo(
                //           context, 'Google signup coming soon!');
                //     },
                //     style: OutlinedButton.styleFrom(
                //       backgroundColor: AppColors.white,
                //       side: const BorderSide(color: AppColors.border),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         SvgPicture.asset(
                //           'assets/images/goggle.svg',
                //           width: 24,
                //           height: 24,
                //         ),
                //         const SizedBox(width: 12),
                //         const Text(
                //           'Continue with Google',
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.w600,
                //             color: AppColors.textPrimary,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Password validation indicator widget
class _ValidationIndicator extends StatelessWidget {
  final String text;
  final bool isValid;

  const _ValidationIndicator({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isValid ? AppColors.primary : AppColors.textSecondary,
        decoration: isValid ? TextDecoration.lineThrough : null,
        decorationColor: isValid ? AppColors.primary : null,
      ),
    );
  }
}

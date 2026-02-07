import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/presentation/screens/auth/login/login_screen.dart';
import 'package:gozapper/presentation/screens/auth/signup/signup_screen.dart';
import 'package:gozapper/presentation/screens/auth/verify/verify_otp_screen.dart';
import 'package:gozapper/presentation/screens/delivery/create_order_screen.dart';
import 'package:gozapper/presentation/screens/delivery/delivery_detail_screen.dart';
import 'package:gozapper/presentation/screens/delivery/delivery_history_screen.dart';
import 'package:gozapper/presentation/screens/delivery/track_delivery_map_screen.dart';
import 'package:gozapper/presentation/screens/auth/forgot_password/forgot_password_screen.dart';
import 'package:gozapper/presentation/screens/auth/forgot_password/reset_password_screen.dart';
import 'package:gozapper/presentation/screens/home/home_screen.dart';
import 'package:gozapper/presentation/screens/billing/payment_billing_screen.dart';
import 'package:gozapper/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:gozapper/presentation/screens/payment/add_payment_method_screen.dart';
import 'package:gozapper/presentation/screens/profile/change_password_screen.dart';
import 'package:gozapper/presentation/screens/profile/edit_profile_screen.dart';
import 'package:gozapper/presentation/screens/profile/profile_screen.dart';
import 'package:gozapper/presentation/screens/settings/advanced_settings_screen.dart';
import 'package:gozapper/presentation/screens/settings/security_settings_screen.dart';
import 'package:gozapper/presentation/screens/splash/splash_screen.dart';
import 'package:gozapper/presentation/screens/profile/support/support_screen.dart';
import 'package:gozapper/presentation/screens/profile/support/support_success_screen.dart';
import 'package:gozapper/presentation/screens/profile/about_us_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verify-otp',
        pageBuilder: (context, state) {
          // Handle both String (just email) and Map (email + password)
          String email = '';
          String? password;

          if (state.extra is Map<String, dynamic>) {
            final data = state.extra as Map<String, dynamic>;
            email = data['email'] ?? '';
            password = data['password'];
          } else if (state.extra is String) {
            email = state.extra as String;
          }

          return MaterialPage(
            key: state.pageKey,
            child: VerifyOtpScreen(email: email, password: password),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentBill,
        name: 'payment-bill',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PaymentBillingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AdvancedSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.securitySettings,
        name: 'security-settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SecuritySettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        pageBuilder: (context, state) {
          final email = state.extra as String;
          return MaterialPage(
            key: state.pageKey,
            child: ResetPasswordScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createOrder,
        name: 'create-order',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CreateOrderScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        name: 'order-details',
        pageBuilder: (context, state) {
          final delivery = state.extra as Delivery;
          return MaterialPage(
            key: state.pageKey,
            child: DeliveryDetailScreen(delivery: delivery),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DeliveryHistoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.trackMap,
        name: 'track-map',
        pageBuilder: (context, state) {
          final delivery = state.extra as Delivery;
          return MaterialPage(
            key: state.pageKey,
            child: TrackDeliveryMapScreen(delivery: delivery),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addPaymentMethod,
        name: 'add-payment-method',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddPaymentMethodScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billingManagement,
        name: 'billing-management',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PaymentBillingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: 'support',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SupportScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.supportSuccess,
        name: 'support-success',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SupportSuccessScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.aboutUs,
        name: 'about-us',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AboutUsScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    ),
  );
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/constants/app_theme.dart';
import 'package:gozapper/core/di/injection.dart';
import 'package:gozapper/core/navigation/app_router.dart';
import 'package:gozapper/core/services/notification_service.dart';
import 'package:gozapper/firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service (local notifications)
  await NotificationService().initialize();

  // Initialize Firebase Cloud Messaging
  await NotificationService().initializeFirebase();

  // Initialize dependencies
  await Injection.init();

  // Initialize Stripe
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Injection.authProvider),
        ChangeNotifierProvider.value(value: Injection.credentialProvider),
        ChangeNotifierProvider.value(value: Injection.deliveryProvider),
        ChangeNotifierProvider.value(value: Injection.paymentMethodProvider),
        ChangeNotifierProvider.value(value: Injection.notificationProvider),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // final isDark = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          );

          return child ?? const SizedBox();
        },
      ),
    );
  }
}

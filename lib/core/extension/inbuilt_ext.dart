import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/widgets/custom_text.dart';

extension ContextExtensions on BuildContext {
  void goNextScreen(String path) {
    kIsWeb ? go(path) : push(path);
  }

  void goNextScreenWithData(String path, {Object? extra}) {
    if (kIsWeb) {
      // Web: Use GoRouter with extra
      go(path, extra: extra);
    } else {
      // Mobile: Use push with arguments
      push(path, extra: extra);
    }
  }

  // Navigate and remove all previous routes
  void goNextScreenAndRemoveUntil(String routeName, {Object? extra}) {
    final router = GoRouter.of(this); // Get the GoRouter instance from context
    if (kIsWeb) {
      // On web, goNamed replaces the current route (effectively clearing history)
      router.goNamed(routeName, extra: extra);
    } else {
      // On mobile, remove all previous routes
      router.pushReplacementNamed(
        "/login",
        // (route) => false, // Removes all routes until false is returned
        extra: extra,
      );
    }
  }

  void goBack() {
    if (kIsWeb) {
      pop();
    } else {
      Navigator.of(this).pop();
    }
  }

  void showInfoDialog({String? title, String? subtitle}) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: CustomText(text: title ?? "", size: 20),
        content: CustomText(text: subtitle ?? "", size: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void hideLoadingDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  void hideKeyboard() {
    // FocusScope.of(this).unfocus(); // hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void copyText({String textToCopy = ""}) {
    Clipboard.setData(ClipboardData(text: textToCopy));
    // toastMsg("Copied!");
  }
}

Future<bool> checkNetwork() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/services/notification_service.dart';

class NotificationActivationDialog extends StatelessWidget {
  const NotificationActivationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.background, // background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bell Icon with animation effect
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 80,
                color: AppColors.white,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Stay Updated!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Don\'t miss out on important updates about your deliveries, order status, and special offers!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textHint,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Activate Now Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final notificationService = NotificationService();
                  final granted =
                      await notificationService.requestNotificationPermission();

                  if (!context.mounted) return;

                  // Pop the dialog once with the result
                  Navigator.of(context).pop(granted);

                  // Show success feedback if granted
                  if (granted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications enabled successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Show a test notification
                    await notificationService.showTestNotification();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Activate Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Maybe Later Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB0B0B0),
              ),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the notification activation dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationActivationDialog(),
    );
  }
}

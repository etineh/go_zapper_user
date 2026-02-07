import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/domain/entities/notification.dart' as notification_entity;
import 'package:gozapper/presentation/providers/notification_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class NotificationDetailScreen extends StatelessWidget {
  final notification_entity.Notification notification;

  const NotificationDetailScreen({
    required this.notification,
    super.key,
  });

  /// Get icon based on notification type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
      case 'delivery_completed':
        return Icons.local_shipping;
      case 'payment':
      case 'transaction':
        return Icons.payment;
      case 'account':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  /// Get icon color based on notification type
  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
      case 'delivery_completed':
        return AppColors.primary;
      case 'payment':
      case 'transaction':
        return AppColors.success;
      case 'account':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  /// Get formatted date
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Yesterday at $hour:$minute';
    } else {
      final month = _getMonthName(dateTime.month);
      return '${dateTime.day} $month ${dateTime.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Share notification
  void _shareNotification() {
    final text = '${notification.title}\n\n${notification.message}';
    Share.share(text);
  }

  /// Delete notification
  Future<void> _deleteNotification(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<NotificationProvider>();
      final success = await provider.deleteNotification(notification.id);

      if (success && context.mounted) {
        context.goBack();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Notification Details',
        onBack: () => context.goBack(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getIconColor(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      size: 40,
                      color: _getIconColor(notification.type),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getIconColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notification.type.replaceAll('_', ' ').toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getIconColor(notification.type),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              notification.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            // Date
            Text(
              _formatDate(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            // Additional info if available
            if (notification.data.isNotEmpty) ...[
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notification.data.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${entry.key}:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.value.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: _shareNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    onPressed: () => _deleteNotification(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

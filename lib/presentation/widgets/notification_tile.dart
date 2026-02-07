import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/domain/entities/notification.dart'
    as notification_entity;
// import 'package:share_plus/share_plus.dart';

class NotificationTile extends StatelessWidget {
  final notification_entity.Notification notification;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const NotificationTile({
    required this.notification,
    required this.onDelete,
    this.onTap,
    super.key,
  });

  /// Get icon based on notification type
  IconData _getIconForType() {
    switch (notification.type.toLowerCase()) {
      case 'delivery':
        return Icons.local_shipping;
      case 'payment':
        return Icons.payment;
      case 'account':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  /// Get icon color based on notification type
  Color _getIconColor() {
    switch (notification.type.toLowerCase()) {
      case 'delivery':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'account':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  /// Show bottom sheet with actions
  void _showActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: AppColors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notification Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              // Share action
              // ListTile(
              //   leading: const Icon(Icons.share, color: AppColors.primary),
              //   title: const Text('Share'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _shareNotification();
              //   },
              // ),
              // Delete action
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// Share notification
  // void _shareNotification() {
  //   final text = '${notification.title}\n\n${notification.message}';
  //   Share.share(text);
  // }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showActionsBottomSheet(context),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            color: AppColors.cardBackground,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getIconColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForType(),
                    color: _getIconColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      notification.timeAgo,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getIconColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notification.type.replaceFirst(
                          notification.type[0],
                          notification.type[0].toUpperCase(),
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getIconColor(),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

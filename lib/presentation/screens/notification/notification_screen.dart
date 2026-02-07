import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/domain/entities/notification.dart' as notification_entity;
import 'package:gozapper/presentation/providers/notification_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:gozapper/presentation/widgets/notification_tile.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load notifications on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<NotificationProvider>(context, listen: false);
        // Load 'all' notifications on first load if not already loaded
        if (!provider.isFilterLoaded && !provider.isLoading) {
          provider.fetchNotifications();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll to bottom for pagination
  void _onScroll() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      provider.loadMoreNotifications();
    }
  }

  /// Handle notification tap to navigate to detail screen
  void _handleNotificationTap(notification_entity.Notification notification) {
    // Navigate to notification detail screen
    context.goNextScreenWithData(
      AppRoutes.notificationDetail,
      extra: notification,
    );
  }

  /// Handle notification delete
  Future<void> _handleNotificationDelete(notification_entity.Notification notification) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.deleteNotification(notification.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Notifications'),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Filter Chips
              _buildFilterChips(provider),

              // Notifications List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refreshNotifications(),
                  child: _buildNotificationsList(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build filter chips for notification types
  Widget _buildFilterChips(NotificationProvider provider) {
    const filters = ['all', 'delivery', 'payment', 'account'];
    const labels = ['All', 'Delivery', 'Payment', 'Account'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(
          filters.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[index]),
              selected: provider.currentFilter == filters[index],
              onSelected: (_) => provider.setFilter(filters[index]),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: provider.currentFilter == filters[index]
                    ? AppColors.white
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(
                color: provider.currentFilter == filters[index]
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build notifications list with grouping and pagination
  Widget _buildNotificationsList(NotificationProvider provider) {
    // Handle loading state
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle error state
    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see updates about your deliveries,\npayments, and account here',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Build grouped notifications list
    final groupedNotifications = provider.groupedNotifications;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _calculateItemCount(groupedNotifications, provider),
      itemBuilder: (context, index) {
        return _buildListItem(context, index, groupedNotifications, provider);
      },
    );
  }

  /// Calculate total item count (headers + notifications + loading indicator)
  int _calculateItemCount(
    Map<String, List<notification_entity.Notification>> grouped,
    NotificationProvider provider,
  ) {
    int count = 0;
    for (final notifications in grouped.values) {
      count += 1 + notifications.length; // 1 header + notifications
    }
    // Add loading indicator if more data
    if (provider.isLoadingMore) {
      count += 1;
    }
    return count;
  }

  /// Build individual list item (header, notification, or loading indicator)
  Widget _buildListItem(
    BuildContext context,
    int index,
    Map<String, List<notification_entity.Notification>> grouped,
    NotificationProvider provider,
  ) {
    // Flatten the grouped map to a list of items
    final items = <Widget>[];
    for (final entry in grouped.entries) {
      items.add(_buildDateHeader(entry.key));
      items.addAll(entry.value.map((n) =>
          _buildNotificationItem(context, n, provider)));
    }

    // Add loading indicator if loading more
    if (provider.isLoadingMore) {
      items.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (index < items.length) {
      return items[index];
    }
    return const SizedBox.shrink();
  }

  /// Build date header widget
  Widget _buildDateHeader(String dateGroup) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        dateGroup,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Build notification item widget
  Widget _buildNotificationItem(
    BuildContext context,
    notification_entity.Notification notification,
    NotificationProvider provider,
  ) {
    return NotificationTile(
      notification: notification,
      onTap: () => _handleNotificationTap(notification),
      onDelete: () => _handleNotificationDelete(notification),
    );
  }
}

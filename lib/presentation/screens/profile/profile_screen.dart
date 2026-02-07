import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/services/notification_service.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = NotificationService();
    final isEnabled = await notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = isEnabled;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.refreshProfile();

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(
        context,
        'Profile updated successfully!',
      );
    } else {
      SnackBarUtils.showError(
        context,
        authProvider.errorMessage ?? 'Failed to refresh profile',
      );
    }
  }

  void _showDisableNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Disable Notifications'),
          ],
        ),
        content: const Text(
          'To disable notifications, please go to your device Settings > Apps > GoZapper > Notifications and turn them off.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open app settings
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Profile'),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          debugPrint("General log: what is userid: ${user?.id}");

          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.white,
                              backgroundImage: user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: (user.photoUrl == null ||
                                      user.photoUrl!.isEmpty)
                                  ? Text(
                                      user.firstName.isNotEmpty
                                          ? user.firstName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () =>
                                    context.goNextScreen(AppRoutes.editProfile),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          "${user.firstName} ${user.lastName.isNotEmpty ? user.lastName[0] : ''}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),

                        const SizedBox(height: 4),
                        // Email verification badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.emailVerified
                                ? AppColors.white.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.emailVerified
                                    ? Icons.verified
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.emailVerified
                                    ? 'Verified'
                                    : 'Not Verified',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    trailing: TextButton.icon(
                      onPressed: () =>
                          context.goNextScreen(AppRoutes.editProfile),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'First Name',
                        value: user.firstName,
                        // onTap: () => context.go(AppRoutes.editProfile),
                      ),
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Last Name',
                        value: user.lastName,
                        // onTap: () => context.go(AppRoutes.editProfile),
                      ),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.phoneNumber != null)
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: user.phoneNumber!,
                          // onTap: () => context.go(AppRoutes.editProfile),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Menu Section
                  _buildSection(
                    title: 'Menu',
                    icon: Icons.menu_outlined,
                    children: [
                      _buildActionTile(
                        icon: Icons.history_outlined,
                        title: 'Order History',
                        subtitle: 'View your past deliveries',
                        onTap: () => context.goNextScreen(AppRoutes.orders),
                      ),
                      _buildActionTile(
                        icon: Icons.payment_outlined,
                        title: 'Billing & Payments',
                        subtitle: 'Manage your payment options',
                        onTap: () =>
                            context.goNextScreen(AppRoutes.paymentBill),
                      ),
                      _buildActionTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Receive push notifications',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            if (value) {
                              // User wants to enable notifications
                              final notificationService = NotificationService();
                              final granted = await notificationService
                                  .requestNotificationPermission();

                              if (granted) {
                                setState(() {
                                  _notificationsEnabled = true;
                                });
                                if (mounted) {
                                  SnackBarUtils.showSuccess(
                                    context,
                                    'Notifications enabled successfully!',
                                  );
                                  // Show test notification
                                  await notificationService
                                      .showTestNotification();
                                }
                              } else {
                                if (mounted) {
                                  SnackBarUtils.showError(
                                    context,
                                    'Notification permission denied',
                                  );
                                }
                              }
                            } else {
                              // User wants to disable notifications
                              _showDisableNotificationDialog();
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      _buildActionTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        subtitle: 'Reach out to support',
                        onTap: () => context.goNextScreen(AppRoutes.support),
                      ),
                      _buildActionTile(
                        icon: Icons.info_outline,
                        title: 'About GoZapper',
                        subtitle: 'Learn more about our app',
                        onTap: () => context.goNextScreen(AppRoutes.aboutUs),
                      ),
                      _buildActionTile(
                        icon: Icons.security_outlined,
                        title: 'Security',
                        subtitle: 'Manage security and privacy',
                        onTap: () =>
                            context.goNextScreen(AppRoutes.securitySettings),
                      ),
                      _buildActionTile(
                        icon: Icons.settings_outlined,
                        title: 'Advanced',
                        subtitle: 'Advanced settings and options',
                        onTap: () => context.goNextScreen(AppRoutes.settings),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    // VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);

              // Use the parent context for logout and navigation
              final authProvider = context.read<AuthProvider>();
              authProvider.logout();

              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

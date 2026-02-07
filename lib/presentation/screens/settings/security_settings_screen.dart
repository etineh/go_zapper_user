import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  bool _locationPermissionEnabled = false;
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionStatus();
  }

  Future<void> _checkLocationPermissionStatus() async {
    setState(() => _isCheckingPermission = true);

    final status = await Permission.location.status;

    if (mounted) {
      setState(() {
        _locationPermissionEnabled = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _handleLocationPermission(bool value) async {
    if (!value) {
      // User wants to disable - just show a dialog and update state
      _showDisableLocationDialog();
      return;
    }

    // User wants to enable - request permission
    setState(() => _isCheckingPermission = true);

    final status = await Permission.location.request();

    if (mounted) {
      setState(() => _isCheckingPermission = false);

      if (status.isDenied) {
        SnackBarUtils.showError(
          context,
          'Location permission denied',
        );
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      } else if (status.isGranted) {
        setState(() => _locationPermissionEnabled = true);
        SnackBarUtils.showSuccess(
          context,
          'Location permission granted',
        );
      } else if (status.isRestricted) {
        SnackBarUtils.showError(
          context,
          'Location permission is restricted',
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: Colors.red),
            SizedBox(width: 12),
            Text('Location Permission Denied'),
          ],
        ),
        content: const Text(
          'Location permission is permanently denied. Please enable it in your device settings to allow GoZapper to track deliveries.',
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
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
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

  void _showDisableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Disable Location?'),
          ],
        ),
        content: const Text(
          'Location access is important for real-time delivery tracking. Disabling it may affect your ability to track deliveries. You can re-enable it anytime in settings.',
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
              'Keep Enabled',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _locationPermissionEnabled = false);
              SnackBarUtils.showInfo(
                context,
                'Location permission disabled',
              );
            },
            child: const Text(
              'Disable',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Location Permit'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why we need your location:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionReason(
                Icons.map_outlined,
                'Real-time Tracking',
                'Track delivery locations in real-time',
              ),
              const SizedBox(height: 12),
              _buildPermissionReason(
                Icons.assignment_outlined,
                'Accurate Delivery',
                'Ensure accurate pickup and drop-off locations',
              ),
              const SizedBox(height: 12),
              _buildPermissionReason(
                Icons.security_outlined,
                'Security',
                'Verify delivery completion at correct locations',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your location is only used during active deliveries.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionReason(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Security Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Security Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Keep your account secure',
                      // 'Keep your account secure by using strong passwords and enabling 2FA.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Password Section
            _buildSection(
              title: 'Password',
              icon: Icons.lock_outline,
              children: [
                _buildActionTile(
                  icon: Icons.lock_reset,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => context.goNextScreen(AppRoutes.changePassword),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Authentication Section
            // _buildSection(
            //   title: 'Authentication',
            //   icon: Icons.security_outlined,
            //   children: [
            //     _buildActionTile(
            //       icon: Icons.shield_outlined,
            //       title: 'Two-Factor Authentication',
            //       subtitle: 'Add extra security to your account',
            //       trailing: Switch(
            //         value: _twoFactorEnabled,
            //         onChanged: (value) {
            //           setState(() {
            //             _twoFactorEnabled = value;
            //           });
            //           SnackBarUtils.showInfo(
            //             context,
            //             value ? '2FA enabled' : '2FA disabled',
            //           );
            //         },
            //         activeColor: AppColors.primary,
            //       ),
            //     ),
            //     _buildActionTile(
            //       icon: Icons.phonelink_lock_outlined,
            //       title: 'Active Sessions',
            //       subtitle: 'Manage your active devices',
            //       onTap: () => SnackBarUtils.showInfo(
            //         context,
            //         'Active sessions coming soon!',
            //       ),
            //     ),
            //   ],
            // ),
            //
            // const SizedBox(height: 16),

            // Privacy Section
            _buildSection(
              title: 'Privacy',
              icon: Icons.privacy_tip_outlined,
              children: [
                _buildActionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Permissions',
                  subtitle: _locationPermissionEnabled
                      ? 'Location access enabled'
                      : 'Allow location access for delivery tracking',
                  trailing: Switch(
                    value: _locationPermissionEnabled,
                    onChanged: _isCheckingPermission
                        ? null
                        : (value) => _handleLocationPermission(value),
                    activeColor: AppColors.primary,
                  ),
                  onTap: _showLocationPermissionInfo,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why we need your location:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionReason(
                        Icons.map_outlined,
                        'Real-time Tracking',
                        'Track delivery locations in real-time',
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionReason(
                        Icons.assignment_outlined,
                        'Accurate Delivery',
                        'Ensure accurate pickup and drop-off locations',
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionReason(
                        Icons.security_outlined,
                        'Security',
                        'Verify delivery completion at correct locations',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your location is only used during active deliveries.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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
}

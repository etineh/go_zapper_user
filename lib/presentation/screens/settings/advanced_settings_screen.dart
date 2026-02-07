import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gozapper/core/constants/app_constants.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  String? dataFilepath;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredentials();
    });
  }

  Future<void> _loadCredentials() async {
    final credentialProvider = context.read<CredentialProvider>();
    await credentialProvider.fetchCredentials();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          // Open the file when notification is tapped
          await OpenFilex.open(details.payload!);
        }
      },
    );
  }

  Future<void> _downloadMyData() async {
    // Show loading dialog
    context.showLoadingDialog();

    const notificationId = 1;

    try {
      // Show progress notification
      const androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        channelDescription: 'Download progress notifications',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
        ongoing: true,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        notificationId,
        'Exporting Data',
        'Preparing your data...',
        notificationDetails,
      );

      // Get profile data from API
      final authProvider = context.read<AuthProvider>();
      final data = await authProvider.exportProfile();

      if (data == null) {
        await _notificationsPlugin.cancel(notificationId);
        if (mounted) {
          SnackBarUtils.showError(
            context,
            authProvider.errorMessage ?? 'Failed to export data',
          );
        }
        return;
      }

      // Update progress - converting data
      // await _notificationsPlugin.show(
      //   notificationId,
      //   'Exporting Data',
      //   'Converting data...',
      //   notificationDetails.copyWith(
      //     android: androidDetails.copyWith(progress: 50),
      //   ),
      // );

      // Convert to formatted JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Get the downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage');
      }

      // Create file with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'gozapper_data_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Write data to file
      await file.writeAsString(jsonString);

      // Show completion notification with tap to open
      const completedAndroidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        channelDescription: 'Download progress notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _notificationsPlugin.show(
        notificationId,
        'Export Complete',
        'Tap to open your data file',
        const NotificationDetails(android: completedAndroidDetails),
        payload: file.path,
      );

      if (mounted) {
        setState(() {
          dataFilepath = file.path;
        });
        context.hideLoadingDialog();
      }
    } catch (e) {
      await _notificationsPlugin.cancel(notificationId);
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to export data: $e',
        );
      }
    }
  }

  Future<void> _clearCache() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear SharedPreferences except auth-related keys
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Define keys to preserve (auth-related)
      final preserveKeys = {
        AppConstants.tokenKey,
        AppConstants.refreshTokenKey,
        AppConstants.userKey,
        AppConstants.isLoggedInKey,
      };

      // Remove all keys except preserved ones
      for (final key in keys) {
        if (!preserveKeys.contains(key)) {
          await prefs.remove(key);
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        SnackBarUtils.showSuccess(
          context,
          'Cache cleared successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        SnackBarUtils.showError(
          context,
          'Failed to clear cache: $e',
        );
      }
    }
  }

  Widget _buildAPICredentialsSection() {
    final authProvider = context.watch<AuthProvider>();
    final credentialProvider = context.watch<CredentialProvider>();
    final user = authProvider.user;
    final credentials = credentialProvider.credentials;
    final isLoading = credentialProvider.status == CredentialStatus.loading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                const Text(
                  '🔑 API Credentials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (credentials.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No credentials found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...credentials.map((credential) {
              final color = credential.environment == 'sandbox'
                  ? Colors.orange
                  : Colors.green;
              return _buildCredentialCard(
                  credential, color, credentialProvider);
            }).toList(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await credentialProvider
                          .createSandboxCredential('Sandbox API Credential');
                      if (success && mounted) {
                        await authProvider.refreshProfile();
                        await _loadCredentials();
                        SnackBarUtils.showSuccess(
                            context, 'Sandbox credential created!');
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Sandbox Credential'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: user?.paymentId != null
                        ? () async {
                            final success = await credentialProvider
                                .createProductionCredential(
                                    'Production API Credential');
                            if (success && mounted) {
                              await authProvider.refreshProfile();
                              await _loadCredentials();
                              SnackBarUtils.showSuccess(
                                  context, 'Production credential created!');
                            }
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Production Credential'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (user?.paymentId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Payment method required for production',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard(
      credential, Color color, CredentialProvider provider) {
    final maskedKey = credential.apiKey.length > 20
        ? '${credential.apiKey.substring(0, 20)}...'
        : credential.apiKey;

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: credential.status ? color : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    credential.environment.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: credential.status,
                    onChanged: (value) async {
                      context.showLoadingDialog();
                      final success = await provider.updateCredentialStatus(
                        credential.id,
                        value,
                      );
                      if (success && mounted) {
                        SnackBarUtils.showSuccess(
                          context,
                          value ? 'Credential enabled' : 'Credential disabled',
                        );
                      } else if (mounted) {
                        SnackBarUtils.showError(
                          context,
                          provider.errorMessage ??
                              'Failed to update credential',
                        );
                      }
                      if (mounted) context.hideLoadingDialog();
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => print("General log: api key tapped $credential"),
                child: Text(
                  'API Key: $maskedKey',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                credential.status ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: credential.status ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialRow(String environment, bool isActive, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            environment,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          isActive ? 'Active' : 'Not Set',
          style: TextStyle(
            fontSize: 14,
            color: isActive ? color : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_circle, color: color, size: 20),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Advanced Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These settings are for advanced users only. Proceed with caution.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // API Credentials Section
            _buildAPICredentialsSection(),

            const SizedBox(height: 16),

            // Account Management Section
            Container(
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Account Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildDangerTile(
                    context: context,
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Management Section
            Container(
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Data Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    context: context,
                    icon: Icons.download_outlined,
                    title: 'Download My Data',
                    subtitle: 'Export all your account data',
                    onTap: _downloadMyData,
                  ),
                  _buildActionTile(
                    context: context,
                    icon: Icons.clear_all_outlined,
                    title: 'Clear Cache',
                    subtitle: 'Free up storage space',
                    onTap: _clearCache,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 34),

            if (dataFilepath != null)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Expanded(
                    child: Text(
                      "Data download to: \n${dataFilepath ?? " "}",
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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

  Widget _buildDangerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.red,
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
                      color: Colors.red,
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
            const Icon(
              Icons.chevron_right,
              color: Colors.red,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => _DeleteAccountDialog(user: user),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final dynamic user;

  const _DeleteAccountDialog({required this.user});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _confirmController;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('Delete Account')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type "${widget.user.firstName}" to confirm:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              onChanged: (value) {
                setState(() {
                  _isConfirmed = value.trim().toLowerCase() ==
                      widget.user.firstName.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isConfirmed ? Colors.red : AppColors.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  _isConfirmed ? Icons.check_circle : Icons.error_outline,
                  color: _isConfirmed ? Colors.green : Colors.grey,
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isConfirmed
              ? () async {
                  // Get root navigator before any operations
                  final navigator = Navigator.of(context, rootNavigator: true);
                  final authProvider = context.read<AuthProvider>();

                  // Close confirmation dialog
                  Navigator.of(context).pop();

                  // Show loading dialog
                  showDialog(
                    context: navigator.context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final success = await authProvider.deleteAccount();

                  // Close loading dialog
                  // navigator.pop();

                  // if (!mounted) return;

                  if (success) {
                    // Use GoRouter to navigate
                    navigator.context.go(AppRoutes.login);

                    // Show success message after a brief delay
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (navigator.context.mounted) {
                        SnackBarUtils.showSuccess(
                          navigator.context,
                          'Account deleted successfully',
                        );
                      }
                    });
                  } else {
                    SnackBarUtils.showError(
                      navigator.context,
                      authProvider.errorMessage ?? 'Failed to delete account',
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Delete Account'),
        ),
      ],
    );
  }
}

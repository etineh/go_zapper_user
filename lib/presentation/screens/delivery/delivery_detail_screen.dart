import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/delivery_status_ext.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/utils/format_utils.dart';
import 'package:gozapper/core/utils/snackbar_utils.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';
import 'package:gozapper/presentation/providers/delivery_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:gozapper/presentation/widgets/driver_rating_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/utils/call_utils.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryDetailScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Timer? _refreshTimer;
  Delivery? _currentDelivery;
  bool _isRefreshing = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.delivery;

    // Fetch delivery details once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        _refreshDeliveryStatus();

        // Start auto-refresh every 10 seconds for active deliveries
        if (!_avoidAutoRefreshTrack()) {
          _startAutoRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _avoidAutoRefreshTrack() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status == 'delivered' ||
        status == 'cancelled' ||
        status == 'created' ||
        status == 'quote' ||
        status == 'pending';
  }

  bool _canBeCancelled() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status != 'delivered' && status != 'cancelled';
  }

  bool _shouldShowTrackButton() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status != OrderStatus.quote.name &&
        status != OrderStatus.pending.name &&
        status != OrderStatus.cancelled.name &&
        status != OrderStatus.delivered.name;
  }

  bool _isConfirmed() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status != 'confirmed';
  }

  bool _isQuote() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status == 'quote' || status == 'pending';
  }

  bool _isCompleted() {
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    return status == 'completed' || status == 'delivered';
  }

  // refresh every 30seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshDeliveryStatus();
    });
  }

  Future<void> _refreshDeliveryStatus() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    final provider = context.read<DeliveryProvider>();
    final updatedDelivery = await provider.trackDelivery(_currentDelivery!.id);

    if (updatedDelivery != null && mounted) {
      setState(() {
        _currentDelivery = updatedDelivery;
        _isRefreshing = false;
      });

      // Stop auto-refresh if delivery is completed
      if (_avoidAutoRefreshTrack()) {
        _refreshTimer?.cancel();
      }
    } else {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context1) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cancel Delivery?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this delivery? This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancellation Reason',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Please provide a reason for cancellation...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Delivery',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context1).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a cancellation reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context1, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel Delivery'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final reason = reasonController.text.trim();
      await _cancelDelivery(reason);
    }

    // reasonController.dispose();
  }

  Future<void> _cancelDelivery(String reason) async {
    context.showLoadingDialog();
    final provider = context.read<DeliveryProvider>();
    final success = await provider.cancelDelivery(_currentDelivery!.id, reason);
    if (mounted) context.hideLoadingDialog();

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'Delivery cancelled successfully');

      context.goBack();
      // Refresh the delivery status
      // _refreshDeliveryStatus();

      // Stop auto-refresh since delivery is now cancelled
      _refreshTimer?.cancel();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to cancel delivery',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRatingDialog() async {
    final result = await DriverRatingDialog.show(
      context,
      driverName: delivery.riderName,
      deliveryId: delivery.id,
    );

    if (result != null && mounted) {
      // TODO: Call API to submit rating when ready
      // final provider = context.read<DeliveryProvider>();
      // final success = await provider.submitDriverRating(
      //   deliveryId: result['deliveryId'],
      //   rating: result['rating'],
      //   comment: result['comment'],
      // );

      SnackBarUtils.showSuccess(
        context,
        'Thank you for rating ${delivery.riderName}!',
      );
    }
  }

  Future<void> _acceptQuote() async {
    // First, check if user is logged in
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 1: Check if user has credentials (sandbox or production)
    final credentialProvider = context.read<CredentialProvider>();

    if (user.sandboxCredential == false && user.productionCredential == false) {
      if (mounted) context.showLoadingDialog();

      // No credentials exist, create sandbox credential automatically
      final credentialCreated =
          await credentialProvider.createSandboxCredential(
        'Auto-generated Sandbox Credential',
      );

      if (mounted) context.hideLoadingDialog();

      if (!credentialCreated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              credentialProvider.errorMessage ??
                  'Failed to create API credential',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Refresh user profile to update credential flags
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sandbox API credential created automatically!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Step 2: Check if user has payment method (paymentId)
    if (user.paymentId == null || user.paymentId!.isEmpty) {
      // Show dialog to add payment method
      if (mounted) {
        _showAddPaymentMethodDialog();
      }
      return;
    }

    // Step 3: User has both credentials and payment method, proceed with accepting quote
    if (mounted) context.showLoadingDialog();

    final deliveryProvider = context.read<DeliveryProvider>();
    final success =
        await deliveryProvider.acceptQuoteById(_currentDelivery!.id);

    if (mounted) context.hideLoadingDialog();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote accepted and payment processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh delivery status
      await _refreshDeliveryStatus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(deliveryProvider.errorMessage ?? 'Failed to accept quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Payment Method Required'),
        content: const Text(
          'You need to add a payment method before accepting this quote. Would you like to add one now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to add payment method screen
              final result = await context.push(AppRoutes.addPaymentMethod);

              // If payment method was added successfully, try to accept quote again
              if (result == true && mounted) {
                await _acceptQuote();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Add Payment Method',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Delivery get delivery => _currentDelivery ?? widget.delivery;

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM, yyyy - hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'to_pickup':
      case 'at_pickup':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = delivery.status.toLowerCase() == 'delivered';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Delivery Details',
        titleColor: AppColors.white,
        backgroundColor: AppColors.primary,
        actions: [
          if (!_avoidAutoRefreshTrack())
            IconButton(
              onPressed: _isRefreshing ? null : _refreshDeliveryStatus,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh status',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDeliveryStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Section with Tracking ID and Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    /// track id and copy icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          delivery.trackingId,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            context.copyText(textToCopy: delivery.trackingId);
                          },
                          child: const Icon(Icons.copy,
                              size: 18, color: AppColors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    if (!_avoidAutoRefreshTrack())
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.trackMap,
                                  extra: delivery),
                              child: const Text(
                                'View Live Tracking  ➡',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(delivery.status),
                        ),
                      ),
                      child: Text(
                        DeliveryPickUpStatus.fromString(delivery.status)
                                    .displayText ==
                                'none'
                            ? delivery.status
                            : DeliveryPickUpStatus.fromString(delivery.status)
                                .displayText,
                        style: TextStyle(
                          color: _getStatusColor(delivery.status),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// date and amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          _formatDate(delivery.createdAt),
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          Icons.attach_money,
                          '${delivery.currency.toUpperCase()} ${FormatUtils.formatAmount(delivery.fee)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Delivery Progress Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDeliveryTimeline(),
              ),

              // Rider Details Card (if assigned)
              if (delivery.riderName.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDetailCard(
                    title: 'Rider Details',
                    icon: Icons.motorcycle,
                    iconColor: AppColors.primary,
                    children: [
                      _buildDetailRow('Name', delivery.riderName),
                      if (delivery.riderPhoneNumber.isNotEmpty)
                        _buildDetailRow('Phone', delivery.riderPhoneNumber),
                      if (delivery.riderVehicle.isNotEmpty)
                        _buildDetailRow('Vehicle', delivery.riderVehicle),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 15),

              // Items Details Card
              if (delivery.items != null && delivery.items!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildItemsCard(),
                ),

              const SizedBox(height: 15),

              if (delivery.items != null && delivery.items!.isNotEmpty)

                // Pickup Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDetailCard(
                    title: 'Pickup Details',
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    children: [
                      _buildDetailRow('Name', delivery.pickupDetails.name),
                      _buildDetailRow('Phone', delivery.pickupDetails.phone),
                      _buildDetailRow(
                          'Address', delivery.pickupDetails.address),
                      _buildDetailRow('Code', delivery.pickupCode),
                      _buildDetailRow(
                        'Scheduled',
                        _formatDateTime(delivery.pickupWindow.startTime),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Drop-off Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDetailCard(
                  title: 'Drop-off Details',
                  icon: Icons.flag,
                  iconColor: Colors.red,
                  children: [
                    _buildDetailRow('Name', delivery.dropOffDetails.name),
                    _buildDetailRow('Phone', delivery.dropOffDetails.phone),
                    _buildDetailRow('Address', delivery.dropOffDetails.address),
                    _buildDetailRow('Code', delivery.dropOffCode),
                    _buildDetailRow(
                      'Expected',
                      _formatDateTime(delivery.dropOffWindow.endTime),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Additional Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDetailCard(
                  title: 'Additional Information',
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  children: [
                    _buildDetailRow(
                      'Contactless Drop-off',
                      delivery.contactlessDropOff ? 'Yes' : 'No',
                    ),
                    _buildDetailRow(
                      'Signature Required',
                      delivery.signatureRequired ? 'Yes' : 'No',
                    ),
                    _buildDetailRow(
                      'If Undeliverable',
                      delivery.actionIfUndeliverable.toUpperCase(),
                    ),
                    _buildDetailRow(
                        'Vehicle Type',
                        FormatUtils.getVehicleType(
                            delivery.requiredVehicleType)),
                    if (delivery.tip != '0')
                      _buildDetailRow(
                        'Tip',
                        '${delivery.currency.toUpperCase()} ${delivery.tip}',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Show Accept Quote button if delivery is still a quote
                    if (_isQuote())
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _acceptQuote,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Accept Quote'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          if (_shouldShowTrackButton()) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.push(AppRoutes.trackMap,
                                      extra: delivery);
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Track on Map'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (_isCompleted()) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showRatingDialog,
                                icon: const Icon(Icons.rate_review),
                                label: const Text('Rate Driver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textSecondary,
                                  foregroundColor: AppColors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(AppRoutes.support),
                              icon: const Icon(Icons.support_agent),
                              label: const Text('Get Help'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_canBeCancelled()) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showCancelDialog,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel Delivery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    final status = DeliveryPickUpStatusStep.fromString(delivery.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Delivery Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimelineStep(
                'Order\nPlaced',
                !_isQuote() && delivery.status.toLowerCase() != 'cancelled',
                // isFirst: true,
              ),
              // _buildTimelineStep(
              //   'Order\nPlaced',
              //   status.reached(DeliveryPickUpStatus.toPickUp),
              // ),

              _buildTimelineLine(
                status.reached(DeliveryPickUpStatusStep.toPickUp),
              ),

              _buildTimelineStep(
                'Item(s)\nPicked',
                status.reached(DeliveryPickUpStatusStep.pickedUp),
              ),

              _buildTimelineLine(
                status.reached(DeliveryPickUpStatusStep.toDropOff),
              ),

              _buildTimelineStep(
                'In\nTransit',
                status.reached(DeliveryPickUpStatusStep.toDropOff),
              ),

              _buildTimelineLine(
                status.reached(DeliveryPickUpStatusStep.atDropOff),
              ),

              _buildTimelineStep(
                'Delivered',
                status.reached(DeliveryPickUpStatusStep.delivered),
                isLast: true,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool isCompleted,
      {bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isCompleted ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (label == 'Phone') ...[
            GestureDetector(
              onTap: () async {
                var isOk = await CallUtils.launcherCaller(value);
                if (isOk != null && mounted) {
                  SnackBarUtils.showError(context, isOk);
                }
              },
              child:
                  const Icon(Icons.phone, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () {
                context.copyText(textToCopy: value);
              },
              child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Items Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${delivery.items!.length} ${delivery.items!.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...delivery.items!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == delivery.items!.length - 1;

            return Column(
              children: [
                _buildItemTile(item),
                if (!isLast) const Divider(height: 24),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemTile(DeliveryItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.inventory_2,
                        color: Colors.grey[400],
                        size: 30,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.inventory_2,
                  color: Colors.grey[400],
                  size: 30,
                ),
        ),
        const SizedBox(width: 12),
        // Item Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildItemDetail(
                    Icons.shopping_cart,
                    'Qty: ${item.quantity}',
                  ),
                  const SizedBox(width: 12),
                  if (item.price != null && item.price!.isNotEmpty)
                    _buildItemDetail(
                      Icons.attach_money,
                      item.price!,
                    ),
                  const SizedBox(width: 12),
                  if (item.weight != null)
                    _buildItemDetail(
                      Icons.scale,
                      '${item.weight} kg',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

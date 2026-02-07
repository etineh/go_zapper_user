import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';
import 'package:gozapper/core/services/notification_service.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/domain/entities/user.dart';
import 'package:gozapper/presentation/providers/delivery_provider.dart';
import 'package:gozapper/presentation/widgets/custom_text.dart';
import 'package:gozapper/presentation/widgets/notification_activation_dialog.dart';
import 'package:gozapper/presentation/widgets/location_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/utils/snackbar_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocation = 'Fetching location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    // Fetch deliveries when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      // print("General log: the user is ${authProvider.user}");
      // Only fetch data if user is authenticated
      if (authProvider.user != null &&
          authProvider.status == AuthStatus.authenticated) {
        context.read<DeliveryProvider>().fetchDeliveries();
      } else {
        // User is not authenticated, redirect to login
        print(
            '⚠️ User not authenticated on home screen, redirecting to login...');
        context.go(AppRoutes.login);
      }

      _checkNotificationPermission();
      _getCurrentLocation();
    });
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = NotificationService();
    final shouldShow = await notificationService.shouldShowActivationDialog();

    if (shouldShow && mounted) {
      // Delay to ensure the screen is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await NotificationActivationDialog.show(context);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String country = place.isoCountryCode ?? '';

        setState(() {
          _currentLocation = '$city, $country';
          _isLoadingLocation = false;
        });
      } else if (mounted) {
        setState(() {
          _currentLocation = 'Location unavailable';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentLocation = 'Location unavailable';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _currentLocation = result['address'] ?? 'Location selected';
      });
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final authProvider = context.read<AuthProvider>();

      // Check if user is authenticated before refreshing
      if (authProvider.user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to refresh data'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Refresh user profile
      await authProvider.refreshProfile();

      // Refresh delivery history
      final deliveryProvider = context.read<DeliveryProvider>();
      await deliveryProvider.fetchDeliveries();

      if (!mounted) return;

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshed successfully!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final deliveryProvider = context.watch<DeliveryProvider>();

    // Listen for session expiration and redirect to login
    if (authProvider.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('🔴 Session expired, redirecting to login...');
          context.go(AppRoutes.login);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: GestureDetector(
            onTap: context.hideKeyboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Cards Row - 2 Combined Cards
                  Row(
                    children: [
                      // Profile + Location Card
                      Expanded(
                        child: _ProfileLocationCard(
                          user: user,
                          currentLocation: _currentLocation,
                          onLocationTap: _openLocationPicker,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Notification + Zap with Us Card
                      Expanded(
                        child: _NotificationZapCard(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  /*
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),

                   */

                  const SizedBox(height: 24),

                  // Current Tracking Section - Only show if there's an active delivery
                  if (deliveryProvider.deliveries.isNotEmpty &&
                      deliveryProvider.deliveries.any((d) =>
                          d.status.toLowerCase() == 'in_delivery' ||
                          d.status.toLowerCase() == 'in delivery')) ...[
                    _CurrentTrackingCard(
                      delivery: deliveryProvider.deliveries.firstWhere(
                        (d) =>
                            d.status.toLowerCase() == 'in_delivery' ||
                            d.status.toLowerCase() == 'in delivery',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Shipping History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (deliveryProvider.deliveries.isNotEmpty) ...[
                        const Text(
                          'Shipping History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.orders);
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Shipping History List
                  deliveryProvider.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : deliveryProvider.deliveries.isEmpty
                          ? _EmptyHistoryWidget()
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: deliveryProvider.deliveries.length > 7
                                  ? 7
                                  : deliveryProvider.deliveries.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 5),
                              itemBuilder: (context, index) {
                                final delivery =
                                    deliveryProvider.deliveries[index];
                                return _ShippingHistoryItem(
                                  delivery: delivery,
                                );
                              },
                            ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Profile + Location Combined Card Widget
class _ProfileLocationCard extends StatelessWidget {
  final User? user;
  final String currentLocation;
  final VoidCallback onLocationTap;

  const _ProfileLocationCard({
    this.user,
    required this.currentLocation,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
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
          // Profile Section
          GestureDetector(
            onTap: () => context.goNextScreen(AppRoutes.profile),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.white,
                  backgroundImage:
                      user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                  child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: user?.fullName ?? 'John Doe',
                        maxLines: 1,
                        shouldBold: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          // Navigate to profile edit
                        },
                        child: const CustomText(
                          text: 'Change Profile',
                          maxLines: 1,
                          size: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Location Section
          GestureDetector(
            onTap: onLocationTap,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        text: 'Location',
                        maxLines: 1,
                        shouldBold: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // SizedBox(height: 4),
                      CustomText(
                        text: currentLocation,
                        maxLines: 1,
                        size: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Notification + Zap with Us Combined Card Widget
class _NotificationZapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
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
          // Notification Section
          Row(
            children: [
              GestureDetector(
                onTap: () => context.goNextScreen(AppRoutes.notifications),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.goNextScreen(AppRoutes.notifications),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Notification',
                        maxLines: 1,
                        size: 15,
                        shouldBold: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // SizedBox(height: 4),
                      CustomText(
                        text: 'Check notifications',
                        maxLines: 1,
                        size: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Zap with Us Section
          GestureDetector(
            onTap: () => context.goNextScreen(AppRoutes.createOrder),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Zap with US',
                        maxLines: 1,
                        size: 14,
                        shouldBold: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // SizedBox(height: 4),
                      CustomText(
                        text: 'Place an Order',
                        maxLines: 1,
                        size: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Current Tracking Card Widget
class _CurrentTrackingCard extends StatelessWidget {
  final Delivery delivery;

  const _CurrentTrackingCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.goNextScreenWithData(AppRoutes.orderDetails, extra: delivery);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image with ShaderMask
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight.withOpacity(0.6),
                      AppColors.primaryLight.withOpacity(0.3),
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.darken,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/tracking_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Tracking',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delivery.trackingId,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.white, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          delivery.pickupDetails.address,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        delivery.status,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shipping History Item Widget
class _ShippingHistoryItem extends StatelessWidget {
  final Delivery delivery;

  const _ShippingHistoryItem({
    required this.delivery,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = delivery.status.toLowerCase() == 'delivered';
    final formattedStatus =
        DeliveryPickUpStatus.fromString(delivery.status).displayText == 'none'
            ? delivery.status
            : DeliveryPickUpStatus.fromString(delivery.status).displayText;

    return GestureDetector(
      onTap: () {
        // print("General log: imageUrl is ${delivery.items!.first.imageUrl}");
        context.goNextScreenWithData(AppRoutes.orderDetails, extra: delivery);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Package Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: _buildPackageIcon(delivery),
            ),

            const SizedBox(width: 8),

            // Item name and Pickup Details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    delivery.items!.first.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(delivery.pickupWindow.startTime),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delivery.pickupDetails.address,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Horizontal Arrow Icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right,
                    color: AppColors.white.withOpacity(0.4), size: 18),
                Icon(Icons.chevron_right,
                    color: AppColors.white.withOpacity(0.7), size: 18),
                const Icon(Icons.chevron_right,
                    color: AppColors.white, size: 18),
              ],
            ),

            const SizedBox(width: 12),

            // Status and Delivery Details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDelivered
                          ? AppColors.white
                          : const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedStatus,
                      style: TextStyle(
                        color: isDelivered
                            ? AppColors.primary
                            : AppColors.textPrimary.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  /// date
                  Text(
                    _formatDate(delivery.dropOffWindow.endTime),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // drop-off address
                  Text(
                    delivery.dropOffDetails.address,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPackageIcon(Delivery delivery) {
  final items = delivery.items;

  if (items != null &&
      items.isNotEmpty &&
      items.first.imageUrl != null &&
      items.first.imageUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        items.first.imageUrl!,
        width: 25,
        height: 25,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.inventory_2,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  return const Icon(
    Icons.inventory_2,
    color: AppColors.primary,
    size: 25,
  );
}

// Empty History Widget
class _EmptyHistoryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'No History Yet!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          const Text(
            'You haven\'t made any deliveries yet.\nStart your first delivery with us now!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Zap with Us Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                context.goNextScreen(AppRoutes.createOrder);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Zap with Us Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/presentation/providers/delivery_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';

class TrackDeliveryMapScreen extends StatefulWidget {
  final Delivery delivery;

  const TrackDeliveryMapScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<TrackDeliveryMapScreen> createState() => _TrackDeliveryMapScreenState();
}

class _TrackDeliveryMapScreenState extends State<TrackDeliveryMapScreen> {
  GoogleMapController? _mapController;
  Timer? _trackingTimer;
  Delivery? _currentDelivery;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.delivery;
    _initializeMap();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _createMarkers();
    _createPolyline();
    setState(() => _isLoading = false);
  }

  void _createMarkers() {
    final delivery = _currentDelivery!;

    _markers = {
      // Pickup marker
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(delivery.pickupLatitude, delivery.pickupLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: delivery.pickupDetails.address,
        ),
      ),

      // Dropoff marker
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(delivery.dropOffLatitude, delivery.dropOffLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Drop-off Location',
          snippet: delivery.dropOffDetails.address,
        ),
      ),

      // Rider marker (if available and in transit)
      if (delivery.riderLatitude != 0 && delivery.riderLongitude != 0)
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(delivery.riderLatitude, delivery.riderLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Rider: ${delivery.riderName}',
            snippet: delivery.riderVehicle,
          ),
        ),
    };
  }

  void _createPolyline() {
    final delivery = _currentDelivery!;

    List<LatLng> polylineCoordinates = [];

    // If rider is tracking, draw line from pickup -> rider -> dropoff
    if (delivery.riderLatitude != 0 && delivery.riderLongitude != 0) {
      polylineCoordinates = [
        LatLng(delivery.pickupLatitude, delivery.pickupLongitude),
        LatLng(delivery.riderLatitude, delivery.riderLongitude),
        LatLng(delivery.dropOffLatitude, delivery.dropOffLongitude),
      ];
    } else {
      // Otherwise, draw direct line from pickup to dropoff
      polylineCoordinates = [
        LatLng(delivery.pickupLatitude, delivery.pickupLongitude),
        LatLng(delivery.dropOffLatitude, delivery.dropOffLongitude),
      ];
    }

    _polylines = {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: polylineCoordinates,
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(30), PatternItem.gap(10)],
      ),
    };
  }

  void _startLiveTracking() {
    // Only track if delivery is in progress
    final status = _currentDelivery?.status.toLowerCase() ?? '';
    if (status != 'in_delivery' &&
        status != 'in delivery' &&
        status != 'confirmed') {
      return;
    }

    // Refresh tracking data every 20 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _refreshDeliveryTracking();
    });
  }

  Future<void> _refreshDeliveryTracking() async {
    final provider = context.read<DeliveryProvider>();
    final updatedDelivery = await provider.trackDelivery(_currentDelivery!.id);

    if (updatedDelivery != null && mounted) {
      setState(() {
        _currentDelivery = updatedDelivery;
        _createMarkers();
        _createPolyline();
      });

      // Stop tracking if delivery is completed
      final status = updatedDelivery.status.toLowerCase();
      if (status == 'delivered' || status == 'cancelled') {
        _trackingTimer?.cancel();
      }
    }
  }

  void _fitMapBounds() {
    if (_mapController == null || _currentDelivery == null) return;

    final delivery = _currentDelivery!;

    // Calculate bounds to include all markers
    double minLat = delivery.pickupLatitude;
    double maxLat = delivery.pickupLatitude;
    double minLng = delivery.pickupLongitude;
    double maxLng = delivery.pickupLongitude;

    // Include dropoff
    minLat =
        minLat < delivery.dropOffLatitude ? minLat : delivery.dropOffLatitude;
    maxLat =
        maxLat > delivery.dropOffLatitude ? maxLat : delivery.dropOffLatitude;
    minLng =
        minLng < delivery.dropOffLongitude ? minLng : delivery.dropOffLongitude;
    maxLng =
        maxLng > delivery.dropOffLongitude ? maxLng : delivery.dropOffLongitude;

    // Include rider if available
    if (delivery.riderLatitude != 0) {
      minLat =
          minLat < delivery.riderLatitude ? minLat : delivery.riderLatitude;
      maxLat =
          maxLat > delivery.riderLatitude ? maxLat : delivery.riderLatitude;
      minLng =
          minLng < delivery.riderLongitude ? minLng : delivery.riderLongitude;
      maxLng =
          maxLng > delivery.riderLongitude ? maxLng : delivery.riderLongitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _currentDelivery!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Track Delivery',
        titleColor: AppColors.white,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: _fitMapBounds,
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit to view',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                delivery.pickupLatitude,
                delivery.pickupLongitude,
              ),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              // Fit bounds after map is created
              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMapBounds();
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(delivery),
          ),

          // Bottom Status Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildStatusCard(delivery),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Delivery delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icons.local_shipping,
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
                      delivery.trackingId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DeliveryPickUpStatus.fromString(delivery.status)
                          .displayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(delivery.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (delivery.status.toLowerCase() == 'in_delivery' ||
                  delivery.status.toLowerCase() == 'in delivery')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.orange),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Delivery delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pickup Info
          _buildLocationRow(
            Icons.location_on,
            'Pickup',
            delivery.pickupDetails.address,
            Colors.green,
          ),
          const SizedBox(height: 12),

          // Rider Info (if available)
          if (delivery.riderName.isNotEmpty) ...[
            _buildLocationRow(
              Icons.motorcycle,
              delivery.riderName,
              delivery.riderVehicle,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          // Dropoff Info
          _buildLocationRow(
            Icons.flag,
            'Drop-off',
            delivery.dropOffDetails.address,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in_delivery':
      case 'in delivery':
      case 'confirmed':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}

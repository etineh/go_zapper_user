import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingHelper {
  /// Convert address to coordinates
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      // Address not found or invalid
      return null;
    }
  }

  /// Convert coordinates to address
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static int _continueRequest = 0;

  /// Get user's current city name
  static Future<String?> getUserCity(BuildContext context) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (_continueRequest < 3) {
          permission = await Geolocator.requestPermission();
          _continueRequest++;
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (_continueRequest < 3 && context.mounted) {
          await _promptToEnableLocation(context);
          _continueRequest++;
        }
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get city
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks[0].locality; // City name
      }

      return null;
    } catch (e) {
      print('Error getting user city: $e');
      return null;
    }
  }

  /// Prompt user to enable location
  static Future<void> _promptToEnableLocation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location'),
        content: const Text(
          'Please enable location services to get your city information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

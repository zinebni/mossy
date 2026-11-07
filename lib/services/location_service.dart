import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Lightweight wrapper around [Geolocator].
/// Location is strictly optional in Mossy and never mandatory for exploration.
class LocationService {
  /// Checks whether device location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[Mossy] LocationService isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Checks current location permission status without prompting.
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[Mossy] LocationService checkPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Requests location permission from the user.
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[Mossy] LocationService requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Attempts to fetch the device's current GPS position.
  /// Returns `null` silently if location service is disabled, permission denied,
  /// or if retrieval times out. Never throws.
  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[Mossy] LocationService getCurrentPosition error (non-fatal): $e');
      return null;
    }
  }
}

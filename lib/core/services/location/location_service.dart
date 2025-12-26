import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ [LOCATION] Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ [LOCATION] Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ [LOCATION] Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      print('📍 [LOCATION] Requesting current location...');
      
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        print('❌ [LOCATION] Location permission not granted');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      print('✅ [LOCATION] Location obtained: ${position.latitude}, ${position.longitude}');
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('❌ [LOCATION] Error getting location: $e');
      return null;
    }
  }
}

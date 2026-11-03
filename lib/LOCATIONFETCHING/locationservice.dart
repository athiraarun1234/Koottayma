import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets the current device location.
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print('Location service is disabled.');
        return null;
      }

      // Check permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      // Request permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          return null;
        }
      }

      // Permission permanently denied
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied.');
        return null;
      }

      // Get current location
      Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');

      return position;
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }
}
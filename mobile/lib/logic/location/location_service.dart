import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks whether location tracking is allowed by the user.
  static Future<bool> isLocationPermissionGranted() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Shows an explicit, polite rationale dialog before asking system permission.
  static Future<bool> requestLocationPermissionWithDialog(BuildContext context) async {
    // 1. Check if location services (GPS hardware) are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.location_off_rounded, color: Colors.orange, size: 40),
            title: const Text('Device GPS is Turned Off'),
            content: const Text(
              'Location services are required to detect your emergency coordinates. Would you like to open settings to turn ON GPS?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
      }
      return false;
    }

    // 2. Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Show explicit permission explanation dialog
      if (context.mounted) {
        final shouldAsk = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.share_location_rounded, color: Colors.redAccent, size: 44),
            title: const Text(
              'Location Tracking Permission',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PulseSync needs your permission to access device location in order to:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text('• Automatically tag emergency incident locations with GPS'),
                Text('• Dispatch the closest responders to disaster zones'),
                Text('• Show your position to dispatchers on the field map'),
                SizedBox(height: 12),
                Text(
                  'Aap location tracking allow karna chahte hain?',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Deny / Not Now', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Allow Tracking'),
              ),
            ],
          ),
        );

        if (shouldAsk != true) {
          return false;
        }
      }

      // Request system permission
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is permanently denied. Enable it in App Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Retrieves current position if permission granted
  static Future<Position?> getCurrentPosition(BuildContext context) async {
    final granted = await requestLocationPermissionWithDialog(context);
    if (!granted) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get GPS location: $e')),
        );
      }
      return null;
    }
  }
}

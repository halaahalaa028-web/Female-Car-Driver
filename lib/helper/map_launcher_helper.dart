import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to launch external turn-by-turn navigation applications (Google Maps, Apple Maps, Waze).
/// Eliminates Google Cloud Directions/Navigation billing by delegating to device-native navigation.
class MapLauncherHelper {
  /// Builds the Google Maps navigation URI for Android (Turn-by-turn mode, 100% free, no API key).
  static Uri buildAndroidGoogleMapsUri(double latitude, double longitude) {
    return Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
  }

  /// Builds the Google Maps URL scheme for iOS.
  static Uri buildIosGoogleMapsUri(double latitude, double longitude) {
    return Uri.parse('comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving');
  }

  /// Builds the Apple Maps URL scheme for iOS.
  static Uri buildAppleMapsUri(double latitude, double longitude) {
    return Uri.parse('maps://?daddr=$latitude,$longitude&dirflg=d');
  }

  /// Builds the Waze navigation URL scheme.
  static Uri buildWazeUri(double latitude, double longitude) {
    return Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');
  }

  /// Builds a universal Google Maps web fallback URL (costs zero Cloud API quota).
  static Uri buildUniversalGoogleMapsUri(double latitude, double longitude) {
    return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');
  }

  /// Builds a Google Maps directions URL showing BOTH points (origin -> destination).
  /// Works with or without the Google Maps app installed and needs no API key.
  static Uri buildDirectionsUri({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng'
      '&destination=$destLat,$destLng&travelmode=driving',
    );
  }

  /// Opens an external map showing the route between two locations.
  static Future<bool> openRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    Future<bool> Function(Uri uri, {LaunchMode mode})? launch,
  }) async {
    final launchFn = launch ?? ((uri, {mode = LaunchMode.platformDefault}) => launchUrl(uri, mode: mode));
    try {
      return await launchFn(
        buildDirectionsUri(originLat: originLat, originLng: originLng, destLat: destLat, destLng: destLng),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapLauncherHelper.openRoute error: $e');
      }
      return false;
    }
  }

  /// Launches the best available external navigation app based on platform and availability.
  static Future<bool> openMap({
    required double latitude,
    required double longitude,
    bool preferWaze = false,
    Future<bool> Function(Uri uri)? canLaunch,
    Future<bool> Function(Uri uri, {LaunchMode mode})? launch,
  }) async {
    final canLaunchFn = canLaunch ?? canLaunchUrl;
    final launchFn = launch ?? ((uri, {mode = LaunchMode.platformDefault}) => launchUrl(uri, mode: mode));

    try {
      if (preferWaze) {
        final wazeUri = buildWazeUri(latitude, longitude);
        if (await canLaunchFn(wazeUri)) {
          return await launchFn(wazeUri, mode: LaunchMode.externalApplication);
        }
      }

      if (!kIsWeb && Platform.isAndroid) {
        final androidUri = buildAndroidGoogleMapsUri(latitude, longitude);
        if (await canLaunchFn(androidUri)) {
          return await launchFn(androidUri, mode: LaunchMode.externalApplication);
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosGoogleUri = buildIosGoogleMapsUri(latitude, longitude);
        if (await canLaunchFn(iosGoogleUri)) {
          return await launchFn(iosGoogleUri, mode: LaunchMode.externalApplication);
        }

        final appleUri = buildAppleMapsUri(latitude, longitude);
        if (await canLaunchFn(appleUri)) {
          return await launchFn(appleUri, mode: LaunchMode.externalApplication);
        }
      }

      final fallbackUri = buildUniversalGoogleMapsUri(latitude, longitude);
      if (await canLaunchFn(fallbackUri)) {
        return await launchFn(fallbackUri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapLauncherHelper.openMap error: $e');
      }
      return false;
    }
  }
}

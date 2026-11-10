// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/helper/map_launcher_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

void main() {
  group('Security & Billing Protection Tests', () {
    test('AppConstants.polylineMapKey is deactivated and contains no live credentials', () {
      // Must not contain Google Cloud API key prefix
      expect(AppConstants.polylineMapKey.contains('AIzaSy'), isFalse);
      expect(AppConstants.polylineMapKey, isEmpty);
    });

    test('All MapLauncherHelper URIs are completely decoupled from API keys', () {
      const double testLat = 30.0444;
      const double testLng = 31.2357;

      final android = MapLauncherHelper.buildAndroidGoogleMapsUri(testLat, testLng);
      final ios = MapLauncherHelper.buildIosGoogleMapsUri(testLat, testLng);
      final apple = MapLauncherHelper.buildAppleMapsUri(testLat, testLng);
      final waze = MapLauncherHelper.buildWazeUri(testLat, testLng);
      final universal = MapLauncherHelper.buildUniversalGoogleMapsUri(testLat, testLng);

      for (final uri in [android, ios, apple, waze, universal]) {
        expect(uri.toString().contains('key='), isFalse);
        expect(uri.toString().contains('AIzaSy'), isFalse);
        expect(uri.queryParameters.containsKey('key'), isFalse);
      }
    });
  });
}

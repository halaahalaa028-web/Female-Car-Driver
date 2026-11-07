import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/helper/map_launcher_helper.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  const double testLat = 30.0444;
  const double testLng = 31.2357;

  group('MapLauncherHelper URI Construction & Security Tests', () {
    test('buildAndroidGoogleMapsUri generates valid turn-by-turn intent without API keys', () {
      final uri = MapLauncherHelper.buildAndroidGoogleMapsUri(testLat, testLng);

      expect(uri.scheme, equals('google.navigation'));
      expect(uri.path, equals('q=$testLat,$testLng&mode=d'));
      expect(uri.toString(), equals('google.navigation:q=$testLat,$testLng&mode=d'));
      expect(uri.toString().contains('key='), isFalse);
    });

    test('buildIosGoogleMapsUri generates valid iOS scheme without API keys', () {
      final uri = MapLauncherHelper.buildIosGoogleMapsUri(testLat, testLng);

      expect(uri.scheme, equals('comgooglemaps'));
      expect(uri.queryParameters['daddr'], equals('$testLat,$testLng'));
      expect(uri.queryParameters['directionsmode'], equals('driving'));
      expect(uri.queryParameters.containsKey('key'), isFalse);
      expect(uri.toString().contains('key='), isFalse);
    });

    test('buildAppleMapsUri generates valid Apple Maps scheme without API keys', () {
      final uri = MapLauncherHelper.buildAppleMapsUri(testLat, testLng);

      expect(uri.scheme, equals('maps'));
      expect(uri.queryParameters['daddr'], equals('$testLat,$testLng'));
      expect(uri.queryParameters['dirflg'], equals('d'));
      expect(uri.queryParameters.containsKey('key'), isFalse);
      expect(uri.toString().contains('key='), isFalse);
    });

    test('buildWazeUri generates valid Waze scheme', () {
      final uri = MapLauncherHelper.buildWazeUri(testLat, testLng);

      expect(uri.scheme, equals('waze'));
      expect(uri.queryParameters['ll'], equals('$testLat,$testLng'));
      expect(uri.queryParameters['navigate'], equals('yes'));
      expect(uri.queryParameters.containsKey('key'), isFalse);
      expect(uri.toString().contains('key='), isFalse);
    });

    test('buildUniversalGoogleMapsUri generates standard web fallback without API keys', () {
      final uri = MapLauncherHelper.buildUniversalGoogleMapsUri(testLat, testLng);

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('www.google.com'));
      expect(uri.path, equals('/maps/dir/'));
      expect(uri.queryParameters['api'], equals('1'));
      expect(uri.queryParameters['destination'], equals('$testLat,$testLng'));
      expect(uri.queryParameters['travelmode'], equals('driving'));
      expect(uri.queryParameters.containsKey('key'), isFalse);
      expect(uri.toString().contains('key='), isFalse);
    });

    test('handles negative and zero coordinates accurately', () {
      const double negLat = -33.8688;
      const double negLng = 151.2093;

      final androidUri = MapLauncherHelper.buildAndroidGoogleMapsUri(negLat, negLng);
      expect(androidUri.path, equals('q=-33.8688,151.2093&mode=d'));
      expect(androidUri.toString(), equals('google.navigation:q=-33.8688,151.2093&mode=d'));

      final appleUri = MapLauncherHelper.buildAppleMapsUri(negLat, negLng);
      expect(appleUri.queryParameters['daddr'], equals('-33.8688,151.2093'));

      final universalUri = MapLauncherHelper.buildUniversalGoogleMapsUri(0.0, 0.0);
      expect(universalUri.queryParameters['destination'], equals('0.0,0.0'));
    });
  });

  group('MapLauncherHelper.openMap Execution & Fallback Tests', () {
    test('launches Waze when preferWaze is true and Waze can be launched', () async {
      Uri? launchedUri;
      final result = await MapLauncherHelper.openMap(
        latitude: testLat,
        longitude: testLng,
        preferWaze: true,
        canLaunch: (uri) async => uri.scheme == 'waze',
        launch: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      expect(result, isTrue);
      expect(launchedUri?.scheme, equals('waze'));
    });

    test('falls back to universal web URL when native schemes are unavailable', () async {
      Uri? launchedUri;
      final result = await MapLauncherHelper.openMap(
        latitude: testLat,
        longitude: testLng,
        preferWaze: false,
        canLaunch: (uri) async => uri.scheme == 'https',
        launch: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      expect(result, isTrue);
      expect(launchedUri?.scheme, equals('https'));
      expect(launchedUri?.host, equals('www.google.com'));
    });

    test('returns false when no launcher can open any URI', () async {
      final result = await MapLauncherHelper.openMap(
        latitude: testLat,
        longitude: testLng,
        canLaunch: (uri) async => false,
      );

      expect(result, isFalse);
    });

    test('catches exceptions and returns false gracefully without crashing', () async {
      final result = await MapLauncherHelper.openMap(
        latitude: testLat,
        longitude: testLng,
        canLaunch: (uri) async => throw Exception('Launch platform channel failure'),
      );

      expect(result, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/map_launcher_helper.dart';
import 'package:ride_sharing_user_app/helper/pickup_distance_helper.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('PickupDistanceHelper.parseGeoJson', () {
    test('reads GeoJSON [lng, lat] order', () {
      final p = PickupDistanceHelper.parseGeoJson([31.2357, 30.0444]);
      expect(p, isNotNull);
      expect(p!.lat, 30.0444);
      expect(p.lng, 31.2357);
    });
    test('returns null for null / short / zero / out of range', () {
      expect(PickupDistanceHelper.parseGeoJson(null), isNull);
      expect(PickupDistanceHelper.parseGeoJson([1.0]), isNull);
      expect(PickupDistanceHelper.parseGeoJson([0, 0]), isNull);
      expect(PickupDistanceHelper.parseGeoJson([200, 10]), isNull);
      expect(PickupDistanceHelper.parseGeoJson([10, 95]), isNull);
      expect(PickupDistanceHelper.parseGeoJson([double.nan, 10]), isNull);
    });
  });

  group('PickupDistanceHelper.distanceKm / format', () {
    test('same point is zero', () {
      expect(PickupDistanceHelper.distanceKm(30, 31, 30, 31), 0);
    });
    test('Cairo Tahrir -> Cairo Airport is about 15-20 km', () {
      final km = PickupDistanceHelper.distanceKm(30.0444, 31.2357, 30.1219, 31.4056);
      expect(km, inInclusiveRange(15, 20));
    });
    test('is symmetric', () {
      final a = PickupDistanceHelper.distanceKm(30.0, 31.0, 30.1, 31.1);
      final b = PickupDistanceHelper.distanceKm(30.1, 31.1, 30.0, 31.0);
      expect(a, closeTo(b, 0.001));
    });
    test('format uses 2 decimals and Km', () {
      expect(PickupDistanceHelper.format(6.4812), '6.48 Km');
      expect(PickupDistanceHelper.format(0), '0.00 Km');
    });
  });

  group('MapLauncherHelper route (both locations)', () {
    test('buildDirectionsUri contains origin and destination, no API key', () {
      final uri = MapLauncherHelper.buildDirectionsUri(
        originLat: 30.1, originLng: 31.2, destLat: 30.2, destLng: 31.3,
      );
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['origin'], '30.1,31.2');
      expect(uri.queryParameters['destination'], '30.2,31.3');
      expect(uri.queryParameters['travelmode'], 'driving');
      expect(uri.toString().contains('key='), isFalse);
    });
    test('openRoute launches externally and returns result', () async {
      Uri? launched;
      LaunchMode? usedMode;
      final ok = await MapLauncherHelper.openRoute(
        originLat: 1, originLng: 2, destLat: 3, destLng: 4,
        launch: (u, {mode = LaunchMode.platformDefault}) async { launched = u; usedMode = mode; return true; },
      );
      expect(ok, isTrue);
      expect(launched!.queryParameters['origin'], '1.0,2.0');
      expect(usedMode, LaunchMode.externalApplication);
    });
    test('openRoute returns false on exception', () async {
      final ok = await MapLauncherHelper.openRoute(
        originLat: 1, originLng: 2, destLat: 3, destLng: 4,
        launch: (u, {mode = LaunchMode.platformDefault}) async => throw Exception('x'),
      );
      expect(ok, isFalse);
    });
  });

  group('DateConverter.ltrIsolate', () {
    test('wraps text in LRI..PDI so dates keep order inside RTL text', () {
      final out = DateConverter.ltrIsolate('05 Nov 2026');
      expect(out.startsWith('⁦'), isTrue);
      expect(out.endsWith('⁩'), isTrue);
      expect(out.contains('05 Nov 2026'), isTrue);
    });
  });
}

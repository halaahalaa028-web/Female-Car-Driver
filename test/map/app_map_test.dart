import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/map/app_map.dart';

void main() {
  group('compat types', () {
    test('markers are identified by id (set semantics used by MapController)', () {
      const a = Marker(markerId: MarkerId('x'), position: LatLng(1, 2));
      const b = Marker(markerId: MarkerId('x'), position: LatLng(3, 4));
      expect({a, b}, hasLength(1));
    });

    test('bounds contain / exclude points', () {
      const bounds = LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(10, 10));
      expect(bounds.contains(const LatLng(5, 5)), isTrue);
      expect(bounds.contains(const LatLng(11, 5)), isFalse);
    });
  });

  testWidgets('AppMap renders markers + polyline and reports ready', (tester) async {
    AppMapController? ctl;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 600,
        child: AppMap(
          initialCameraPosition: const CameraPosition(target: LatLng(30.04, 31.23), zoom: 12),
          markers: {const Marker(markerId: MarkerId('a'), position: LatLng(30.04, 31.23))},
          polylines: {
            const Polyline(
                polylineId: PolylineId('p'), points: [LatLng(30.0, 31.2), LatLng(30.1, 31.3)], color: Colors.red)
          },
          onMapCreated: (c) => ctl = c,
        ),
      ),
    ));
    await tester.pump();
    expect(ctl, isNotNull);
    await ctl!.moveCamera(CameraUpdate.newLatLngBounds(
        const LatLngBounds(southwest: LatLng(30.0, 31.2), northeast: LatLng(30.1, 31.3)), 20));
    await tester.pump();
    final visible = await ctl!.getVisibleRegion();
    expect(visible.contains(const LatLng(30.05, 31.25)), isTrue);
  });

  testWidgets('AppMap draws polygons + dashed polylines and can take a snapshot', (tester) async {
    AppMapController? ctl;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 600,
        child: AppMap(
          initialCameraPosition: const CameraPosition(target: LatLng(30.04, 31.23), zoom: 12),
          polygons: {
            const Polygon(
                polygonId: PolygonId('z'),
                points: [LatLng(30.0, 31.2), LatLng(30.1, 31.2), LatLng(30.1, 31.3)],
                fillColor: Color(0x2200FF00),
                strokeColor: Colors.green)
          },
          polylines: {
            Polyline(
                polylineId: const PolylineId('d'),
                points: const [LatLng(30.0, 31.2), LatLng(30.1, 31.3)],
                color: Colors.green,
                width: 2,
                patterns: [PatternItem.dash(10), PatternItem.gap(8)])
          },
          onMapCreated: (c) => ctl = c,
        ),
      ),
    ));
    await tester.pump();
    expect(ctl, isNotNull);
    expect(tester.takeException(), isNull);
    // toImage needs real async work: run it outside the fake-async zone.
    final bytes = await tester.runAsync(() => ctl!.takeSnapshot(pixelRatio: 1));
    expect(bytes, isNotNull);
    expect(bytes!.sublist(1, 4), [0x50, 0x4E, 0x47]); // PNG header
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/map/widgets/captain_to_pickup_distance_widget.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(TripDetail t) => GetMaterialApp(
    home: Scaffold(body: Center(child: CaptainToPickupDistanceWidget(rideRequest: t))),
  );

  testWidgets('falls back to estimated distance and shows the eye button when location is unavailable', (tester) async {
    final trip = TripDetail()..estimatedDistance = 6.48;
    await tester.pumpWidget(wrap(trip));
    await tester.pump();
    expect(find.textContaining('6.48 Km'), findsOneWidget);
    expect(find.byKey(const Key('captain_pickup_eye_button')), findsOneWidget);
    expect(find.byIcon(Icons.remove_red_eye_outlined), findsOneWidget);
  });

  testWidgets('tapping the eye without a location does not crash', (tester) async {
    final trip = TripDetail()..estimatedDistance = 1.0;
    await tester.pumpWidget(wrap(trip));
    await tester.pump();
    await tester.tap(find.byKey(const Key('captain_pickup_eye_button')));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

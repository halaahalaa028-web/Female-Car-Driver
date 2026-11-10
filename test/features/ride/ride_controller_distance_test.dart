import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';

class FakeRideService implements RideServiceInterface {
  final List<String> arrivalPickupCalls = [];
  final List<String> arrivalDestinationCalls = [];

  @override
  Future<Response> arrivalPickupPoint(String tripId) async {
    arrivalPickupCalls.add(tripId);
    return const Response(statusCode: 200);
  }

  @override
  Future<Response> arrivalDestination(String tripId, String type) async {
    arrivalDestinationCalls.add('$tripId:$type');
    return const Response(statusCode: 200);
  }

  @override
  Future<Response> getRideDetails(String tripId, {bool fromHomeScreen = false}) async {
    return const Response(statusCode: 200, body: {
      'data': {
        'encoded_polyline': '',
        'due_amount': 0.0,
      }
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RideController rideController;
  late FakeRideService fakeRideService;

  setUp(() {
    Get.reset();
    fakeRideService = FakeRideService();
    rideController = RideController(rideServiceInterface: fakeRideService);
  });

  group('RideController - Local Distance & Arrival Optimization Tests', () {
    test('does not throw or invoke APIs when tripDetail is null', () {
      rideController.tripDetail = null;
      rideController.updateRemainingDistanceLocally(30.0444, 31.2357);

      expect(rideController.matchedMode, isNull);
      expect(fakeRideService.arrivalPickupCalls, isEmpty);
      expect(fakeRideService.arrivalDestinationCalls, isEmpty);
    });

    test('ignores calculation when trip status is not active (e.g. completed)', () {
      rideController.tripDetail = TripDetail(
        id: 'trip_101',
        currentStatus: 'completed',
        pickupCoordinates: PickupCoordinates(coordinates: [31.2357, 30.0444]),
      );

      rideController.updateRemainingDistanceLocally(30.0444, 31.2357);

      expect(rideController.matchedMode, isNull);
      expect(fakeRideService.arrivalPickupCalls, isEmpty);
    });

    test('computes distance to pickup and triggers arrivalPickupPoint when <= 100m for pending status', () {
      // GeoJSON: [longitude, latitude]
      rideController.tripDetail = TripDetail(
        id: 'trip_pickup_1',
        currentStatus: 'pending',
        pickupCoordinates: PickupCoordinates(coordinates: [31.2357, 30.0444]),
      );

      // Driver is within ~10 meters of pickup
      rideController.updateRemainingDistanceLocally(30.04445, 31.2357);

      expect(rideController.matchedMode, isNotNull);
      expect(rideController.matchedMode!.distance, isNotNull);
      expect(rideController.matchedMode!.distance! * 1000, lessThanOrEqualTo(100));
      expect(fakeRideService.arrivalPickupCalls, contains('trip_pickup_1'));
    });

    test('computes distance to pickup but does not trigger arrival when > 100m', () {
      rideController.tripDetail = TripDetail(
        id: 'trip_pickup_2',
        currentStatus: 'pending',
        pickupCoordinates: PickupCoordinates(coordinates: [31.2357, 30.0444]),
      );

      // Driver is ~1km away
      rideController.updateRemainingDistanceLocally(30.0544, 31.2357);

      expect(rideController.matchedMode, isNotNull);
      expect(rideController.matchedMode!.distance! * 1000, greaterThan(100));
      expect(fakeRideService.arrivalPickupCalls, isEmpty);
    });

    test('computes distance to destination and triggers arrivalDestination when <= 100m for ongoing status', () {
      rideController.tripDetail = TripDetail(
        id: 'trip_dest_1',
        currentStatus: 'ongoing',
        isPaused: false,
        destinationCoordinates: PickupCoordinates(coordinates: [31.2357, 30.0444]),
      );

      // Driver is within ~10 meters of destination
      rideController.updateRemainingDistanceLocally(30.04445, 31.2357);

      expect(rideController.matchedMode, isNotNull);
      expect(rideController.matchedMode!.distance! * 1000, lessThanOrEqualTo(100));
      expect(fakeRideService.arrivalDestinationCalls, contains('trip_dest_1:destination'));
    });

    test('does not trigger arrivalDestination when trip is paused even if <= 100m', () {
      rideController.tripDetail = TripDetail(
        id: 'trip_dest_paused',
        currentStatus: 'ongoing',
        isPaused: true,
        destinationCoordinates: PickupCoordinates(coordinates: [31.2357, 30.0444]),
      );

      rideController.updateRemainingDistanceLocally(30.04445, 31.2357);

      expect(rideController.matchedMode, isNotNull);
      expect(fakeRideService.arrivalDestinationCalls, isEmpty);
    });
  });
}

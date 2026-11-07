import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_body.dart';
import 'package:ride_sharing_user_app/features/profile/domain/services/profile_service_interface.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

class _FakeProfileService implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Vehicle Color Constants & Model Tests', () {
    test('AppConstants.carColors contains default prompt and valid color options', () {
      expect(AppConstants.carColors, isNotEmpty);
      expect(AppConstants.carColors.first, equals('select_car_color'));
      expect(AppConstants.carColors.contains('white'), isTrue);
      expect(AppConstants.carColors.contains('black'), isTrue);
      expect(AppConstants.carColors.contains('silver'), isTrue);
      expect(AppConstants.carColors.contains('red'), isTrue);
      expect(AppConstants.carColors.contains('blue'), isTrue);
    });

    test('VehicleBody serializes vehicle_color to JSON correctly', () {
      final body = VehicleBody(
        brandId: 'brand_1',
        modelId: 'model_1',
        categoryId: 'cat_1',
        licencePlateNumber: '123-XYZ',
        licenceExpireDate: '2027-01-01',
        vinNumber: 'VIN123',
        transmission: 'auto',
        fuelType: 'petrol',
        driverId: 'driver_1',
        ownership: 'driver',
        parcelCapacityWeight: '50',
        vehicleColor: 'red',
      );

      final json = body.toJson();
      expect(json['vehicle_color'], equals('red'));
      expect(json['brand_id'], equals('brand_1'));
    });

    test('VehicleBody deserializes vehicle_color from JSON correctly', () {
      final jsonMap = {
        'brand_id': 'brand_1',
        'model_id': 'model_1',
        'category_id': 'cat_1',
        'licence_plate_number': '123-XYZ',
        'licence_expire_date': '2027-01-01',
        'vin_number': 'VIN123',
        'transmission': 'auto',
        'fuel_type': 'petrol',
        'driver_id': 'driver_1',
        'ownership': 'driver',
        'parcel_weight_capacity': '50',
        'vehicle_color': 'black',
      };

      final body = VehicleBody.fromJson(jsonMap);
      expect(body.vehicleColor, equals('black'));
      expect(body.brandId, equals('brand_1'));
    });

    test('Vehicle model serializes and deserializes vehicle_color correctly', () {
      final vehicleJson = {
        'id': 'v_1',
        'licence_plate_number': '456-ABC',
        'licence_expire_date': '2026-12-31',
        'vin_number': 'VIN789',
        'transmission': 'manual',
        'fuel_type': 'octane',
        'ownership': 'driver',
        'documents': <String>[],
        'is_active': true,
        'created_at': '2026-01-01',
        'vehicle_request_status': 'approved',
        'deny_note': null,
        'parcel_weight_capacity': 25.0,
        'vehicle_color': 'silver',
      };

      final vehicle = Vehicle.fromJson(vehicleJson);
      expect(vehicle.vehicleColor, equals('silver'));

      final serialized = vehicle.toJson();
      expect(serialized['vehicle_color'], equals('silver'));
    });
  });

  group('ProfileController - Car Color State Management Tests', () {
    late ProfileController profileController;

    setUp(() {
      profileController = ProfileController(
        profileServiceInterface: _FakeProfileService(),
      );
    });

    test('Initial selectedCarColor is select_car_color', () {
      expect(profileController.selectedCarColor, equals('select_car_color'));
    });

    test('setCarColor updates selectedCarColor state', () {
      profileController.setCarColor('white', false);
      expect(profileController.selectedCarColor, equals('white'));

      profileController.setCarColor('blue', true);
      expect(profileController.selectedCarColor, equals('blue'));
    });

    test('clearVehicleData resets selectedCarColor back to select_car_color', () {
      profileController.setCarColor('gold', false);
      expect(profileController.selectedCarColor, equals('gold'));

      profileController.clearVehicleData();
      expect(profileController.selectedCarColor, equals('select_car_color'));
    });
  });
}

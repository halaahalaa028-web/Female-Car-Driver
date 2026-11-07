import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/home/widgets/vehicle_color_dropdown_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/categoty_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/vehicle_brand_model.dart';
import 'package:ride_sharing_user_app/features/profile/domain/services/profile_service_interface.dart';
import 'package:ride_sharing_user_app/features/profile/widgets/vehicle_details_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';
import 'package:ride_sharing_user_app/features/splash/domain/services/splash_service_interface.dart';

class _FakeProfileService implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSplashController extends SplashController {
  _TestSplashController({required super.splashServiceInterface});

  @override
  ConfigModel? get config => ConfigModel(parcelWeightUnit: 'kg');
}

void main() {
  late ProfileController profileController;
  late _TestSplashController splashController;

  setUp(() {
    Get.reset();
    profileController = ProfileController(
      profileServiceInterface: _FakeProfileService(),
    );
    splashController = _TestSplashController(
      splashServiceInterface: _FakeSplashService(),
    );
    Get.put<ProfileController>(profileController);
    Get.put<SplashController>(splashController);
  });

  tearDown(() {
    Get.reset();
  });

  group('VehicleColorDropdownWidget Tests', () {
    testWidgets('Renders dropdown and updates controller upon selecting a color', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: _TestTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: VehicleColorDropdownWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VehicleColorDropdownWidget), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(profileController.selectedCarColor, equals('select_car_color'));

      // Tap the dropdown to open menu
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'red' item
      final redItem = find.text('Red').last;
      expect(redItem, findsOneWidget);
      await tester.tap(redItem);
      await tester.pumpAndSettle();

      expect(profileController.selectedCarColor, equals('red'));
    });
  });

  group('VehicleDetailsWidget Car Color Display Tests', () {
    testWidgets('Displays vehicle color row when vehicleColor is present', (WidgetTester tester) async {
      profileController.profileInfo = ProfileInfo(
        id: '123',
        vehicle: Vehicle(
          id: 'v1',
          category: Category(id: 'c1', name: 'Sedan', type: 'Car'),
          brand: Brand(id: 'b1', name: 'Toyota'),
          model: VehicleModels(id: 'm1', name: 'Corolla'),
          licencePlateNumber: 'ABC-1234',
          licenceExpireDate: '2028-12-31T00:00:00.000',
          fuelType: 'petrol',
          vehicleColor: 'white',
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: _TestTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: VehicleDetailsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Car Color'), findsOneWidget);
      expect(find.text('White'), findsOneWidget);
    });

    testWidgets('Gracefully omits vehicle color row when vehicleColor is null', (WidgetTester tester) async {
      profileController.profileInfo = ProfileInfo(
        id: '123',
        vehicle: Vehicle(
          id: 'v1',
          category: Category(id: 'c1', name: 'Sedan', type: 'Car'),
          brand: Brand(id: 'b1', name: 'Toyota'),
          model: VehicleModels(id: 'm1', name: 'Corolla'),
          licencePlateNumber: 'ABC-1234',
          licenceExpireDate: '2028-12-31T00:00:00.000',
          fuelType: 'petrol',
          vehicleColor: null,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: _TestTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: VehicleDetailsWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Car Color'), findsNothing);
      expect(find.text('Fuel Type'), findsOneWidget);
    });
  });
}

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'car_color': 'Car Color',
      'select_car_color': 'Select Car Color',
      'vehicle_category_type': 'Vehicle Category Type',
      'vehicle_category': 'Vehicle Category',
      'vehicle_brand': 'Vehicle Brand',
      'vehicle_model': 'Vehicle Model',
      'license_number_plate': 'License Plate',
      'license_expire_date': 'License Expire Date',
      'fuel_type': 'Fuel Type',
      'red': 'Red',
      'white': 'White',
      'black': 'Black',
      'silver': 'Silver',
      'unlimited': 'Unlimited',
    },
  };
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/services/profile_service_interface.dart';

class FakeProfileService implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProfileController profileController;
  late FakeProfileService fakeProfileService;

  setUp(() {
    fakeProfileService = FakeProfileService();
    profileController = ProfileController(profileServiceInterface: fakeProfileService);
  });

  group('ProfileController - Vehicle Documents State & Validation Tests', () {
    test('Initial vehicle document state is empty and validation fails', () {
      expect(profileController.licenceFrontDoc, isNull);
      expect(profileController.licenceBackDoc, isNull);
      expect(profileController.carFrontDoc, isNull);
      expect(profileController.carBackDoc, isNull);
      expect(profileController.areAllVehicleDocumentsSelected(), isFalse);
      expect(profileController.documents, isEmpty);
    });

    test('Partial document selection still fails areAllVehicleDocumentsSelected', () {
      profileController.licenceFrontDoc = PlatformFile(name: 'lic_front.jpg', size: 100, path: '/path/lic_front.jpg');
      profileController.licenceBackDoc = PlatformFile(name: 'lic_back.jpg', size: 100, path: '/path/lic_back.jpg');
      profileController.carFrontDoc = PlatformFile(name: 'car_front.jpg', size: 100, path: '/path/car_front.jpg');

      expect(profileController.areAllVehicleDocumentsSelected(), isFalse);
    });

    test('Selecting all 4 documents passes areAllVehicleDocumentsSelected', () {
      profileController.licenceFrontDoc = PlatformFile(name: 'lic_front.jpg', size: 100, path: '/path/lic_front.jpg');
      profileController.licenceBackDoc = PlatformFile(name: 'lic_back.jpg', size: 100, path: '/path/lic_back.jpg');
      profileController.carFrontDoc = PlatformFile(name: 'car_front.jpg', size: 100, path: '/path/car_front.jpg');
      profileController.carBackDoc = PlatformFile(name: 'car_back.jpg', size: 100, path: '/path/car_back.jpg');

      expect(profileController.areAllVehicleDocumentsSelected(), isTrue);
    });

    test('removeVehicleDocumentSlot clears specified slot and resyncs documents', () {
      profileController.licenceFrontDoc = PlatformFile(name: 'lic_front.jpg', size: 100, path: '/path/lic_front.jpg');
      profileController.licenceBackDoc = PlatformFile(name: 'lic_back.jpg', size: 100, path: '/path/lic_back.jpg');
      profileController.carFrontDoc = PlatformFile(name: 'car_front.jpg', size: 100, path: '/path/car_front.jpg');
      profileController.carBackDoc = PlatformFile(name: 'car_back.jpg', size: 100, path: '/path/car_back.jpg');

      profileController.removeVehicleDocumentSlot('licence_front');
      expect(profileController.licenceFrontDoc, isNull);
      expect(profileController.areAllVehicleDocumentsSelected(), isFalse);
      expect(profileController.documents.length, equals(3));

      profileController.removeVehicleDocumentSlot('licence_back');
      expect(profileController.licenceBackDoc, isNull);
      expect(profileController.documents.length, equals(2));

      profileController.removeVehicleDocumentSlot('car_front');
      expect(profileController.carFrontDoc, isNull);
      expect(profileController.documents.length, equals(1));

      profileController.removeVehicleDocumentSlot('car_back');
      expect(profileController.carBackDoc, isNull);
      expect(profileController.documents, isEmpty);
    });

    test('clearVehicleData completely resets all 4 slots and documents list', () {
      profileController.licenceFrontDoc = PlatformFile(name: 'lic_front.jpg', size: 100, path: '/path/lic_front.jpg');
      profileController.licenceBackDoc = PlatformFile(name: 'lic_back.jpg', size: 100, path: '/path/lic_back.jpg');
      profileController.carFrontDoc = PlatformFile(name: 'car_front.jpg', size: 100, path: '/path/car_front.jpg');
      profileController.carBackDoc = PlatformFile(name: 'car_back.jpg', size: 100, path: '/path/car_back.jpg');

      profileController.clearVehicleData();

      expect(profileController.licenceFrontDoc, isNull);
      expect(profileController.licenceBackDoc, isNull);
      expect(profileController.carFrontDoc, isNull);
      expect(profileController.carBackDoc, isNull);
      expect(profileController.documents, isEmpty);
      expect(profileController.listOfDocuments, isEmpty);
      expect(profileController.areAllVehicleDocumentsSelected(), isFalse);
    });
  });
}

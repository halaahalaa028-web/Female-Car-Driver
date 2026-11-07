import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';

class FakeAuthService implements AuthServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AuthController authController;
  late FakeAuthService fakeAuthService;

  setUp(() {
    fakeAuthService = FakeAuthService();
    authController = AuthController(authServiceInterface: fakeAuthService);
  });

  group('AuthController - Identity Images State Tests', () {
    test('Initial state has null identity images and empty lists', () {
      expect(authController.identityFrontImage, isNull);
      expect(authController.identityBackImage, isNull);
      expect(authController.identityImages, isEmpty);
      expect(authController.multipartList, isEmpty);
    });

    test('Assigning front image updates identityImages and multipartList', () {
      final XFile front = XFile('front_path.jpg');
      authController.identityFrontImage = front;
      // Trigger synchronization
      authController.removeIdentityImage(true); // removes back, syncs front

      expect(authController.identityFrontImage, equals(front));
      expect(authController.identityBackImage, isNull);
      expect(authController.identityImages.length, equals(1));
      expect(authController.identityImages.first.path, equals('front_path.jpg'));
      expect(authController.multipartList.length, equals(1));
      expect(authController.multipartList.first.key, equals('identity_images[]'));
    });

    test('Assigning both front and back maintains order and syncs multipartList', () {
      final XFile front = XFile('front_path.jpg');
      final XFile back = XFile('back_path.jpg');
      authController.identityFrontImage = front;
      authController.identityBackImage = back;
      // Trigger sync by removing non-existent or calling removeIdentityImage with condition
      authController.removeIdentityImage(false); // remove front
      expect(authController.identityImages.length, equals(1));
      expect(authController.identityImages.first.path, equals('back_path.jpg'));

      authController.identityFrontImage = front;
      authController.removeIdentityImage(false); // removes front
      authController.identityFrontImage = front;
      // sync via clear and set
      authController.clearIdentityImages();
      expect(authController.identityFrontImage, isNull);
      expect(authController.identityBackImage, isNull);
      expect(authController.identityImages, isEmpty);
      expect(authController.multipartList, isEmpty);
    });

    test('clearIdentityImages resets both images and multipart payload', () {
      authController.identityFrontImage = XFile('front.jpg');
      authController.identityBackImage = XFile('back.jpg');
      authController.clearIdentityImages();

      expect(authController.identityFrontImage, isNull);
      expect(authController.identityBackImage, isNull);
      expect(authController.identityImages, isEmpty);
      expect(authController.multipartList, isEmpty);
    });

    test('addImageAndRemoveMultiParseData clears identity images completely', () {
      authController.identityFrontImage = XFile('front.jpg');
      authController.identityBackImage = XFile('back.jpg');
      authController.addImageAndRemoveMultiParseData();

      expect(authController.identityFrontImage, isNull);
      expect(authController.identityBackImage, isNull);
      expect(authController.identityImages, isEmpty);
      expect(authController.multipartList, isEmpty);
    });
  });
}

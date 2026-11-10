import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';

/// In-memory auth service: records calls and returns canned answers.
class _FakeAuthService extends Fake implements AuthServiceInterface {
  Future<dynamic> Function() onLogin = () async => const Response(statusCode: 200);
  Future<dynamic> Function() onSendOtp = () async => const Response(statusCode: 200);
  Future<dynamic> Function() onVerifyOtp = () async => const Response(statusCode: 200);

  int loginCalls = 0;
  int sendOtpCalls = 0;
  String? savedToken;
  final List<String> tokenWrites = [];

  @override
  Future<dynamic> login({required String phone, required String password}) {
    loginCalls++;
    return onLogin();
  }

  @override
  Future<dynamic> sendOtp({required String phone}) {
    sendOtpCalls++;
    return onSendOtp();
  }

  @override
  Future<dynamic> verifyOtp({required String phone, required String otp}) => onVerifyOtp();

  @override
  Future<bool?> saveUserToken(String token, String zoneId) async {
    savedToken = token;
    tokenWrites.add(token);
    return true;
  }

  @override
  String getZonId() => 'zone-1';

  @override
  Future<dynamic> updateToken() async => const Response(statusCode: 200);

  @override
  Future<void> saveUserCredential(String code, String number, String password) async {}

  @override
  Future<bool> clearUserCredentials() async => true;
}

/// Records every UI side effect instead of touching GetX navigation.
class _FakeEffects extends AuthSideEffects {
  _FakeEffects({this.cfg, Future<Response?> Function()? profile})
      : profile = profile ??
            (() async => const Response(statusCode: 200, body: {
                  'data': {'id': 'driver-1'}
                }));

  final ConfigModel? cfg;
  Future<Response?> Function() profile;

  final List<String> messages = [];
  final List<bool> messageIsError = [];
  final List<int> reportedStatuses = [];
  final List<String> events = [];

  @override
  ConfigModel? get config => cfg;
  @override
  Future<Response?> loadProfile() => profile();
  @override
  void startPusher() => events.add('pusher');
  @override
  void loadZones() => events.add('zones');
  @override
  void showMessage(String message, {bool isError = true}) {
    messages.add(message);
    messageIsError.add(isError);
  }

  @override
  void reportError(Response response) => reportedStatuses.add(response.statusCode ?? -1);
  @override
  void openVerification(String countryCode, String number, VerificationForm form) =>
      events.add('verification:$countryCode$number:${form.name}');
  @override
  void openResetPassword(String phoneNumber) => events.add('reset:$phoneNumber');
  @override
  void openHome({required bool zoneMissing, required dynamic profileBody}) =>
      events.add(zoneMissing ? 'access_location' : 'home');
  @override
  void showSignUpApproveDialog() => events.add('approve_dialog');
}

void main() {
  late _FakeAuthService service;
  late AuthController controller;

  _FakeEffects wire({ConfigModel? config, Future<Response?> Function()? profile}) {
    final _FakeEffects fx = _FakeEffects(cfg: config ?? ConfigModel(isSmsGateway: true, otpResendTime: 30), profile: profile);
    controller.effects = fx;
    return fx;
  }

  setUp(() {
    Get.reset();
    service = _FakeAuthService();
    controller = AuthController(authServiceInterface: service);
  });

  group('login()', () {
    test('success: saves token, starts pusher, loads zones + profile, opens home', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire();

      await controller.login('+20', '1000000001', 'password1');

      expect(service.savedToken, 'abc123');
      expect(fx.events, ['pusher', 'zones', 'home']);
      expect(fx.messages, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('200 with an EMPTY token never starts a session', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': ''}
          });
      final _FakeEffects fx = wire();

      await controller.login('+20', '1000000001', 'password1');

      expect(service.tokenWrites, isEmpty);
      expect(fx.events, isEmpty);
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('200 with a missing token / data / non-map body does not crash', () async {
      for (final dynamic body in <dynamic>[
        {'data': {}},
        {'data': null},
        {'message': 'ok'},
        '<html>proxy</html>',
        null,
      ]) {
        service.onLogin = () async => Response(statusCode: 200, body: body);
        final _FakeEffects fx = wire();
        await controller.login('+20', '1000000001', 'password1');
        expect(service.tokenWrites, isEmpty, reason: 'body: $body');
        expect(fx.messages, ['login_failed_try_again'], reason: 'body: $body');
        expect(controller.isLoading, isFalse);
      }
    });

    test('202 + phone not verified opens the verification screen (SMS gateway)', () async {
      service.onLogin = () async => const Response(statusCode: 202, body: {
            'data': {'is_phone_verified': 0}
          });
      final _FakeEffects fx = wire();

      await controller.login('+20', '1000000001', 'password1');

      expect(fx.events, ['verification:+201000000001:login']);
      expect(service.tokenWrites, isEmpty);
    });

    test('202 + phone not verified without any OTP gateway tells the user', () async {
      service.onLogin = () async => const Response(statusCode: 202, body: {
            'data': {'is_phone_verified': 0}
          });
      final _FakeEffects fx = wire(config: ConfigModel(isSmsGateway: false, isFirebaseOtpVerification: false));

      await controller.login('+20', '1000000001', 'password1');

      expect(fx.messages, ['sms_gateway_not_integrate']);
      expect(fx.events, isEmpty);
    });

    test('202 for another reason (pending approval / no data) shows a neutral message and does not crash', () async {
      for (final dynamic body in <dynamic>[
        {'message': 'Waiting for approval'},
        {'data': null},
        null,
      ]) {
        service.onLogin = () async => Response(statusCode: 202, body: body);
        final _FakeEffects fx = wire();
        await controller.login('+20', '1000000001', 'password1');
        expect(fx.messages, hasLength(1), reason: 'body: $body');
        expect(fx.messageIsError.single, isFalse);
        expect(fx.events, isEmpty);
        expect(service.tokenWrites, isEmpty);
      }
    });

    test('profile fetch FAILS after login: the session token is dropped, nothing navigates', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => const Response(statusCode: 500));

      await controller.login('+20', '1000000001', 'password1');

      expect(service.tokenWrites, ['abc123', '']);
      expect(fx.reportedStatuses, [500]);
      expect(fx.events, isNot(contains('home')));
      expect(controller.isLoading, isFalse);
    });

    test('profile fetch 401 does not rewrite the token (ApiChecker logs out)', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => const Response(statusCode: 401));

      await controller.login('+20', '1000000001', 'password1');

      expect(service.tokenWrites, ['abc123']);
      expect(fx.reportedStatuses, [401]);
    });

    test('profile fetch returns null: token dropped and the user is told', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => null);

      await controller.login('+20', '1000000001', 'password1');

      expect(service.tokenWrites, ['abc123', '']);
      expect(fx.messages, ['login_failed_try_again']);
      expect(fx.events, isNot(contains('home')));
    });

    test('profile fetch THROWS: token dropped, generic error, loading reset', () async {
      service.onLogin = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'abc123'}
          });
      final _FakeEffects fx = wire(profile: () async => throw Exception('boom'));

      await controller.login('+20', '1000000001', 'password1');

      expect(service.tokenWrites, ['abc123', '']);
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('server errors go through the central error handler', () async {
      for (final int status in [403, 422, 429, 500, 1]) {
        service.onLogin = () async => Response(statusCode: status);
        final _FakeEffects fx = wire();
        await controller.login('+20', '1000000001', 'password1');
        expect(fx.reportedStatuses, [status]);
        expect(service.tokenWrites, isEmpty);
      }
    });

    test('null response from the service does not crash', () async {
      service.onLogin = () async => null;
      final _FakeEffects fx = wire();
      await controller.login('+20', '1000000001', 'password1');
      expect(fx.messages, ['something_went_wrong']);
    });

    test('an exception thrown by the service is caught and loading is reset', () async {
      service.onLogin = () async => throw Exception('socket');
      final _FakeEffects fx = wire();
      await controller.login('+20', '1000000001', 'password1');
      expect(fx.messages, ['login_failed_try_again']);
      expect(controller.isLoading, isFalse);
    });

    test('a second tap while a login is running is ignored', () async {
      service.onLogin = () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Response(statusCode: 200, body: {
          'data': {'token': 't'}
        });
      };
      wire();
      final Future<void> first = controller.login('+20', '1000000001', 'password1');
      final Future<void> second = controller.login('+20', '1000000001', 'password1');
      await Future.wait([first, second]);
      expect(service.loginCalls, 1);
    });
  });

  group('sendOtp()', () {
    test('a second request for the same phone inside the cooldown does not hit the server', () async {
      final _FakeEffects fx = wire();
      final Response a = await controller.sendOtp(countryCode: '+20', number: '1000000001');
      final Response b = await controller.sendOtp(countryCode: '+20', number: '1000000001');
      expect(a.statusCode, 200);
      expect(b.statusCode, 200);
      expect(service.sendOtpCalls, 1);
      expect(fx.messages, ['otp_sent_successfully']);
    });

    test('simultaneous taps share one request', () async {
      service.onSendOtp = () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Response(statusCode: 200);
      };
      wire();
      await Future.wait([
        controller.sendOtp(countryCode: '+20', number: '1000000001'),
        controller.sendOtp(countryCode: '+20', number: '1000000001'),
        controller.sendOtp(countryCode: '+20', number: '1000000001'),
      ]);
      expect(service.sendOtpCalls, 1);
      expect(controller.isOtpSending, isFalse);
    });

    test('different phones are independent', () async {
      wire();
      await controller.sendOtp(countryCode: '+20', number: '1000000001');
      await controller.sendOtp(countryCode: '+20', number: '1000000002');
      expect(service.sendOtpCalls, 2);
    });

    test('a 429 blocks further sends and tells the user to wait', () async {
      service.onSendOtp = () async => const Response(statusCode: 429, headers: {'retry-after': '40'});
      final _FakeEffects fx = wire();

      final Response first = await controller.sendOtp(countryCode: '+20', number: '1000000001');
      expect(first.statusCode, 429);
      expect(fx.reportedStatuses, [429]);

      final Response second = await controller.sendOtp(countryCode: '+20', number: '1000000002');
      expect(second.statusCode, 429);
      expect(service.sendOtpCalls, 1, reason: 'blocked locally, server not called again');
      expect(fx.messages.single, 'too_many_attempts_wait');
    });

    test('a failed send is not remembered as "sent"', () async {
      service.onSendOtp = () async => const Response(statusCode: 500);
      wire();
      await controller.sendOtp(countryCode: '+20', number: '1000000001');
      service.onSendOtp = () async => const Response(statusCode: 200);
      await controller.sendOtp(countryCode: '+20', number: '1000000001');
      expect(service.sendOtpCalls, 2);
    });

    test('exception from the service becomes a connection error', () async {
      service.onSendOtp = () async => throw Exception('socket');
      final _FakeEffects fx = wire();
      final Response r = await controller.sendOtp(countryCode: '+20', number: '1000000001');
      expect(r.statusCode, 1);
      expect(fx.reportedStatuses, [1]);
      expect(controller.isOtpSending, isFalse);
    });
  });

  group('otpVerification()', () {
    test('wrong code (HTTP 200 + otp_mismatch_404) is reported as an error status', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {'response_code': 'otp_mismatch_404'});
      final _FakeEffects fx = wire();
      final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
      expect(r?.statusCode, 404);
      expect(fx.events, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('login verification with a token starts a session', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok'}
          });
      final _FakeEffects fx = wire();
      final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
      expect(r?.statusCode, 200);
      expect(service.savedToken, 'tok');
      expect(fx.events, ['zones', 'home']);
    });

    test('login verification with an empty / missing token is rejected', () async {
      for (final dynamic body in <dynamic>[
        {'data': {'token': ''}},
        {'data': {}},
        {'data': null},
        null,
      ]) {
        service.onVerifyOtp = () async => Response(statusCode: 200, body: body);
        final _FakeEffects fx = wire();
        final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
        expect(r?.statusCode, 502, reason: 'body: $body');
        expect(service.tokenWrites, isEmpty);
        expect(fx.messages, ['login_failed_try_again']);
        expect(fx.events, isEmpty);
      }
    });

    test('profile failure after OTP login drops the token', () async {
      service.onVerifyOtp = () async => const Response(statusCode: 200, body: {
            'data': {'token': 'tok'}
          });
      final _FakeEffects fx = wire(profile: () async => const Response(statusCode: 500));
      await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
      expect(service.tokenWrites, ['tok', '']);
      expect(fx.events, isNot(contains('home')));
    });

    test('forgot-password verification continues to reset password', () async {
      final _FakeEffects fx = wire();
      final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.reset);
      expect(r?.statusCode, 200);
      expect(fx.events, ['reset:+201000000001']);
    });

    test('Firebase verification without a session does not crash', () async {
      final _FakeEffects fx = wire(config: ConfigModel(isFirebaseOtpVerification: true));
      final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
      expect(r?.statusCode, 400);
      expect(fx.messages, ['something_went_wrong']);
      expect(controller.isLoading, isFalse);
    });

    test('429 / network / server errors are reported, not treated as a wrong code', () async {
      for (final int status in [429, 1, 500]) {
        service.onVerifyOtp = () async => Response(statusCode: status);
        final _FakeEffects fx = wire();
        final Response? r = await controller.otpVerification('+201000000001', '123456', from: VerificationForm.login);
        expect(r?.statusCode, status);
        expect(fx.reportedStatuses, [status]);
      }
    });
  });
}

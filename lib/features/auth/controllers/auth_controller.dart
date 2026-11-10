import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/verification_from_enum.dart';
import 'package:ride_sharing_user_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:ride_sharing_user_app/features/map/controllers/otp_time_count_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/domain/models/config_model.dart';
import 'package:ride_sharing_user_app/helper/country_code_picke.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/helper/otp_send_guard.dart';

import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_in_screen.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/approve_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/reset_password_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/verification_screen.dart';
import 'package:ride_sharing_user_app/features/location/screens/access_location_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/snackbar_widget.dart';



class AuthController extends GetxController implements GetxService {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});


  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _isOtpSending = false;
  bool get isLoading => _isLoading;
  bool get acceptTerms => _acceptTerms;
  bool get isOtpSending => _isOtpSending;
  final String _mobileNumber = '';
  String get mobileNumber => _mobileNumber;
  XFile? _pickedProfileFile ;
  XFile? get pickedProfileFile => _pickedProfileFile;
  XFile identityImage = XFile('');
  List<XFile> identityImages = [];
  List<MultipartBody> multipartList = [];
  List<MultipartDocument> otherDocuments = [];
  FilePickerResult? _otherFile;
  PlatformFile? objFile;
  String countryDialCode = '+880';
  bool isParcelShare = true;
  bool isRideShare = true;

  void setCountryCode(String code){
    countryDialCode = code;
    update();
  }

  TextEditingController fNameController = TextEditingController();
  TextEditingController lNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController identityNumberController = TextEditingController();
  TextEditingController referralCodeController = TextEditingController();

  FocusNode fNameNode = FocusNode();
  FocusNode lNameNode = FocusNode();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();
  FocusNode confirmPasswordNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode addressNode = FocusNode();
  FocusNode identityNumberNode = FocusNode();
  FocusNode referralNode = FocusNode();


  XFile? identityFrontImage;
  XFile? identityBackImage;

  void addImageAndRemoveMultiParseData(){
    multipartList.clear();
    identityImages.clear();
    identityFrontImage = null;
    identityBackImage = null;
    update();
  }

  void updateServiceType(bool ride){
    if(ride){
      isRideShare = !isRideShare;
    }else{
      isParcelShare = !isParcelShare;
    }
    update();
  }

  void pickIdentityImage(bool isBack) async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (isBack) {
        identityBackImage = picked;
      } else {
        identityFrontImage = picked;
      }
      _syncIdentityImagesList();
      update();
    }
  }

  void removeIdentityImage(bool isBack) {
    if (isBack) {
      identityBackImage = null;
    } else {
      identityFrontImage = null;
    }
    _syncIdentityImagesList();
    update();
  }

  void _syncIdentityImagesList() {
    identityImages.clear();
    multipartList.clear();
    if (identityFrontImage != null) {
      identityImages.add(identityFrontImage!);
      multipartList.add(MultipartBody('identity_images[]', identityFrontImage));
    }
    if (identityBackImage != null) {
      identityImages.add(identityBackImage!);
      multipartList.add(MultipartBody('identity_images[]', identityBackImage));
    }
  }

  void clearIdentityImages({bool notify = false}) {
    identityFrontImage = null;
    identityBackImage = null;
    identityImages.clear();
    multipartList.clear();
    if (notify) {
      update();
    }
  }

  void pickImage(bool isBack, bool isProfile) async {
       if(isProfile){
        _pickedProfileFile = (await ImagePicker().pickImage(source: ImageSource.gallery));
      } else{
         identityImage = (await ImagePicker().pickImage(source: ImageSource.gallery)) ?? XFile('');
         if (identityImage.path.isNotEmpty) {
           identityImages.add(identityImage);
           multipartList.add(MultipartBody('identity_images[]', identityImage));
         }
      }
    update();
  }

  void removeImage(int index){
    if (index >= 0 && index < identityImages.length) {
      identityImages.removeAt(index);
      multipartList.removeAt(index);
      update();
    }
  }

  Future<bool> pickOtherFile() async {
    _otherFile = (await FilePicker.platform.pickFiles(
      type: FileType.custom,
        withReadStream: true,
      allowedExtensions: ['cvc', 'cvs', 'doc','jpeg','jpg','pdf','png','webp','xls','xlsx'],
    ))!;
    if (_otherFile != null) {
      objFile = _otherFile!.files.single;
      otherDocuments.add(MultipartDocument('upload_documents[]', objFile));
    }
    update();
    return true;
  }

  void removeFile(int index) async {
    otherDocuments.removeAt(index);
    update();
  }

  void clearOtherDocuments() {
    otherDocuments.clear();
  }

  final List<String> _identityTypeList = ['passport', 'driving_license', 'nid', ];
  List<String> get identityTypeList => _identityTypeList;
  String _identityType = '';
  String get identityType => _identityType;

  void setIdentityType (String setValue){
    _identityType = setValue;
    update();
  }


  /// Collaborators with side effects (navigation, snackbars, other
  /// controllers). Kept behind one object so the login/OTP logic can be unit
  /// tested with a fake.
  AuthSideEffects effects = const AuthSideEffects();

  /// Decides whether a new OTP request may go out (cooldown / 429 block).
  final OtpSendGuard otpGuard = OtpSendGuard();
  final Map<String, Future<Response>> _otpInFlight = {};

  static dynamic _dataOf(Response? response) {
    final dynamic body = response?.body;
    return body is Map ? body['data'] : null;
  }

  static String _tokenOf(Response? response) {
    final dynamic data = _dataOf(response);
    return (data is Map ? data['token'] : null)?.toString().trim() ?? '';
  }

  static bool _isPhoneNotVerified(Response? response) {
    final dynamic data = _dataOf(response);
    return data is Map && data['is_phone_verified'] == 0;
  }

  Future<void> login(String countryCode, String phone, String password) async {
    if (_isLoading) return; // ignore double taps while a login is running
    _isLoading = true;
    update();
    final String fullPhoneNumber = countryCode + phone;
    bool tokenSaved = false;

    try {
      final Response? response = await authServiceInterface.login(phone: fullPhoneNumber, password: password);

      if (response == null) {
        effects.showMessage('something_went_wrong'.tr);
      } else if (response.statusCode == 200) {
        final String token = _tokenOf(response);
        if (token.isEmpty) {
          // 200 but no token: never continue with an empty session.
          effects.showMessage('login_failed_try_again'.tr);
        } else {
          await setUserToken(token);
          tokenSaved = true;
          effects.startPusher();
          await _continueLogin(countryCode, phone, password);
        }
      } else if (response.statusCode == 202) {
        if (_isPhoneNotVerified(response)) {
          final ConfigModel? config = effects.config;
          if (config?.isFirebaseOtpVerification ?? false) {
            firebaseOtpSend(countryCode: countryCode, number: phone, from: VerificationForm.login);
          } else if (config?.isSmsGateway ?? false) {
            effects.openVerification(countryCode, phone, VerificationForm.login);
          } else {
            effects.showMessage('sms_gateway_not_integrate'.tr);
          }
        } else {
          // 202 for any other reason (e.g. account waiting for approval).
          effects.showMessage(ApiChecker.messageFor(response), isError: false);
        }
      } else {
        // 4xx / 5xx / no connection / HTML pages / rate limit ...
        effects.reportError(response);
      }
    } catch (_) {
      if (tokenSaved) await setUserToken('');
      effects.showMessage('login_failed_try_again'.tr);
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// After the token is saved: register the FCM token, load zones and open
  /// the home screen (once the profile could be loaded).
  Future<void> _continueLogin(String code, String phone, String password) async {
    try {
      await updateToken();
    } catch (_) {
      // a failed FCM registration must not block the login
    }
    effects.loadZones();
    await _navigateLogin(code, phone, password);
  }


  bool logging = false;
  Future<void> logOut() async {
    logging = true;
    update();
    Response? response = await authServiceInterface.logOut();
    if(response!.statusCode == 200){
      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<ProfileController>().stopLocationRecord();
      logging = false;
      Get.back();
      // Start from the Home tab next time (otherwise the last tab is restored after re-login).
      Get.find<BottomMenuController>().resetNavBar();
      Get.offAll(()=> const SignInScreen());

      PusherHelper().pusherDisconnectPusher();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
    }else{
      logging = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> permanentDelete() async {
    logging = true;
    update();
    Response? response = await authServiceInterface.permanentDelete();
    if(response!.statusCode == 200){
      Get.find<RideController>().updateRoute(false, notify: true);
      Get.find<ProfileController>().stopLocationRecord();
      logging = false;
      Get.back();
      // Start from the Home tab next time (otherwise the last tab is restored after re-login).
      Get.find<BottomMenuController>().resetNavBar();
      Get.offAll(()=> const SignInScreen());
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
      showCustomSnackBar('successfully_delete_account'.tr, isError: false);
    }else{
      logging = false;
      ApiChecker.checkApi(response);
    }
    update();
  }




  Future<void> register(String code, SignUpBody signUpBody) async {
    final ConfigModel? configModel = Get.find<SplashController>().config;

    _isLoading = true;
    update();
    Response? response = await authServiceInterface.registration(signUpBody: signUpBody,profileImage: pickedProfileFile,identityImage: multipartList,documents: otherDocuments);
    if(response!.statusCode == 200){
      fNameController.clear();
      lNameController.clear();
      passwordController.clear();
      phoneController.clear();
      confirmPasswordController.clear();
      emailController.clear();
      addressController.clear();
      identityNumberController.clear();
      _pickedProfileFile = null;
      clearIdentityImages();
      referralCodeController.clear();
      otherDocuments.clear();
      _isLoading = false;

      if(configModel?.verification ?? false){
        if (configModel?.isFirebaseOtpVerification ?? false) {
          Get.find<AuthController>().firebaseOtpSend(
            countryCode: code,
            number: signUpBody.phone?.replaceAll(code, '') ?? '',
            from: VerificationForm.login,
          );

        } else if(configModel?.isSmsGateway ?? false){
          Get.to(()=> VerificationScreen(
            countryCode: code,
            number: signUpBody.phone?.replaceAll(code, '') ?? '',
            form: VerificationForm.login,
          ));

        }else{
        showCustomSnackBar('sms_gateway_not_integrate'.tr);
      }

      }else{
        showCustomSnackBar('registration_completed_successfully'.tr, isError: false);
        Get.offAll(()=> const SignInScreen());
      }
      Get.find<ProfileController>().updateFirstTimeShowBottomSheet(true);
    }else{
      _isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
  }


  Future<void> _navigateLogin(String code,String phone, String password) async {
    if (_isActiveRememberMe) {
      saveUserCredential(code ,phone, password);
    } else {
      clearUserCredential();
    }
    final Response? value = await effects.loadProfile();
    if (value == null) {
      await setUserToken(''); // keep language & other prefs, only drop the session
      effects.showMessage('login_failed_try_again'.tr);
    } else if (value.statusCode == 200) {
      effects.openHome(zoneMissing: getZoneId() == '', profileBody: value.body);
    } else {
      // Token was issued but the profile can't be loaded: show why and
      // drop the half-created session instead of leaving the user stuck.
      effects.reportError(value);
      if (value.statusCode != 401) {
        await setUserToken('');
      }
    }
  }

  /// Sends an OTP. Calls for the same phone while one is in flight share the
  /// same request, a code sent less than the resend time ago is reused, and a
  /// 429 from the server blocks further sends until `Retry-After`.
  Future<Response> sendOtp({required String countryCode,  required String number}) {
    final String phone = countryCode + number;
    final Future<Response>? inFlight = _otpInFlight[phone];
    if (inFlight != null) return inFlight;
    final Future<Response> request = _sendOtpOnce(phone).whenComplete(() {
      // Block body on purpose: returning the removed future from the callback
      // would make whenComplete wait on itself (deadlock).
      _otpInFlight.remove(phone);
    });
    _otpInFlight[phone] = request;
    return request;
  }

  Future<Response> _sendOtpOnce(String phone) async {
    final OtpSendDecision decision = otpGuard.check(phone,
        cooldownSeconds: OtpSendGuard.cooldownSecondsFor(effects.config?.otpResendTime));
    if (decision == OtpSendDecision.blockedByServer) {
      effects.showMessage('too_many_attempts_wait'.tr
          .replaceAll('{s}', '${otpGuard.blockedSecondsLeft()}'));
      return const Response(statusCode: 429);
    }
    if (decision == OtpSendDecision.reuseLastCode) {
      return const Response(statusCode: 200);
    }

    _isOtpSending = true;
    update();
    Response response;
    try {
      response = (await authServiceInterface.sendOtp(phone: phone)) ?? const Response(statusCode: 1);
    } catch (_) {
      response = const Response(statusCode: 1);
    }
    _isOtpSending = false;
    if (response.statusCode == 200) {
      otpGuard.markSent(phone);
      effects.showMessage('otp_sent_successfully'.tr, isError: false);
    } else {
      if (response.statusCode == 429) {
        otpGuard.markRateLimited(ApiChecker.retryAfterSeconds(response));
      }
      effects.reportError(response);
    }
    update();
    return response;
  }

  Future<void> firebaseOtpSend({required String countryCode, required String number, bool canRoute = true, required VerificationForm from})async {
    _isOtpSending = true;
    update();

    Response? response = await authServiceInterface.isUserRegistered(phone: countryCode + number);
    if(response!.statusCode == 200){
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode + number,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          _isOtpSending = false;
          update();

          if(e.code == 'invalid-phone-number') {
            showCustomSnackBar('please_submit_a_valid_phone_number'.tr);
          }else{
            showCustomSnackBar(e.message?.replaceAll('_', ' ') ?? '');
          }

        },
        codeSent: (String vId, int? resendToken) {

          _isOtpSending = false;
          update();
          if(canRoute){
            Get.to(() =>  VerificationScreen(countryCode: countryCode, number: number, session: vId, form: from));
          }

        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }else{
      _isOtpSending = false;
      ApiChecker.checkApi(response);
      update();
    }

  }




  Future<Response?> otpVerification(String phoneNumber, String otp,  {String password = '', required VerificationForm from, String? session}) async{
    _isLoading = true;
    update();

    try {
      final bool firebase = effects.config?.isFirebaseOtpVerification ?? false;
      if (firebase && (session == null || session.isEmpty)) {
        effects.showMessage('something_went_wrong'.tr);
        return const Response(statusCode: 400);
      }
      final Response response = (firebase
              ? await authServiceInterface.verifyFirebaseOtp(phone: phoneNumber, otp: otp, session: session!)
              : await authServiceInterface.verifyOtp(phone: phoneNumber, otp: otp)) ??
          const Response(statusCode: 1);

      if (response.statusCode != 200) {
        effects.reportError(response);
        return response;
      }
      final dynamic body = response.body;
      if (body is Map && body['response_code'] == 'otp_mismatch_404') {
        // The server answers a wrong code with HTTP 200 + otp_mismatch_404;
        // give callers a real error status so they can show "incorrect OTP".
        effects.reportError(response);
        return Response(statusCode: 404, body: response.body, statusText: response.statusText);
      }

      if (from == VerificationForm.signUp) {
        clearVerificationCode();
        effects.showSignUpApproveDialog();
      } else if (from == VerificationForm.login) {
        final String token = _tokenOf(response);
        if (token.isEmpty) {
          // Verified, but no token came back: never continue with an empty session.
          effects.showMessage('login_failed_try_again'.tr);
          return Response(statusCode: 502, body: response.body);
        }
        clearVerificationCode();
        await setUserToken(token);
        final String countryCode = CountryCodeHelper.getCountryCode(phoneNumber) ?? '';
        await _continueLogin(countryCode, phoneNumber.replaceAll(countryCode, ''), password);
      } else {
        clearVerificationCode();
        effects.openResetPassword(phoneNumber);
      }
      return response;
    } catch (_) {
      effects.showMessage('something_went_wrong'.tr);
      return const Response(statusCode: 500);
    } finally {
      _isLoading = false;
      update();
    }
  }


  Future<void> forgetPassword(String phone) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.forgetPassword(phone);
    if (response!.statusCode  == 200) {
      _isLoading = false;
      snackBarWidget('successfully_sent_otp'.tr, isError: false);
    }else{
      _isLoading = false;
      snackBarWidget('invalid_number'.tr);
    }
    update();
  }


  Future<void> resetPassword(String phone, String password) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.resetPassword(phone, password);
    if (response!.statusCode == 200) {
      snackBarWidget('password_change_successfully'.tr, isError: false);
      Get.offAll(()=> const SignInScreen());
    }else{
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }


  Future<void> changePassword(String password, String newPassword) async {
    _isLoading = true;
    update();
    Response? response = await authServiceInterface.changePassword(password, newPassword);
    if (response!.statusCode == 200) {
      snackBarWidget('password_change_successfully'.tr, isError: false);
      Get.offAll(()=> const DashboardScreen());
    }else{
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }




  bool updateFcm = false;
  Future<void> updateToken() async {
    updateFcm = true;
    update();
    Response? response =  await authServiceInterface.updateToken();
    if(response?.statusCode == 200){
      updateFcm = false;
    }else{
      updateFcm = false;
      ApiChecker.checkApi(response!);
    }
    update();
  }



  String _verificationCode = '';
  String _otp = '';
  String get otp => _otp;
  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    if(_verificationCode.isNotEmpty){
      _otp = _verificationCode;
    }
    update();
  }

  void clearVerificationCode({bool isUpdate = true}){
    _otp = '';
    _verificationCode = '';
    if(isUpdate){
      update();
    }
  }


  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    update();
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  void setRememberMe() {
    _isActiveRememberMe = true;
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  Future<bool> clearSharedData() async{
    return authServiceInterface.clearSharedData();
  }

  void saveUserCredential(String code,String number, String password) {
    authServiceInterface.saveUserCredential(code, number, password);
  }

  String getUserNumber() {
    return authServiceInterface.getUserNumber();
  }

  String getUserCountryCode() {
    return authServiceInterface.getUserCountryCode();
  }

  String getLoginCountryCode() {
    return authServiceInterface.getLoginCountryCode();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  bool isNotificationActive() {
    return authServiceInterface.isNotificationActive();
  }

  void toggleNotificationSound(){
    authServiceInterface.toggleNotificationSound(!isNotificationActive());
    update();
  }

  Future<bool> clearUserCredential() async {
    return authServiceInterface.clearUserCredentials();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  String getDeviceToken() {
    return authServiceInterface.getDeviceToken();
  }

  Future <void> setUserToken(String token) async{
    authServiceInterface.saveUserToken(token, getZoneId());
  }


  Future <void> updateZoneId(String zoneId) async{
    authServiceInterface.updateZone(zoneId);
  }

  String getZoneId() {
    return authServiceInterface.getZonId();
  }

  void saveRideCreatedTime(){
    authServiceInterface.saveRideCreatedTime(DateTime.now());
  }

  void remainingTime() async{
    String time = await authServiceInterface.remainingTime();
    if(time.isNotEmpty){
      DateTime oldTime = DateTime.parse(time);
      DateTime newTime = DateTime.now();
      int diff =  newTime.difference(oldTime).inSeconds;
      Get.find<OtpTimeCountController>().resumeCountingTime(diff);
    }
  }
}


/// Side effects used by [AuthController] (navigation, snackbars, other
/// controllers). Replaced with a fake in unit tests.
class AuthSideEffects {
  const AuthSideEffects();

  ConfigModel? get config => Get.find<SplashController>().config;
  Future<Response?> loadProfile() => Get.find<ProfileController>().getProfileInfo();
  void startPusher() => PusherHelper.initializePusher();
  void loadZones() => Get.find<OutOfZoneController>().getZoneList();
  void showMessage(String message, {bool isError = true}) => showCustomSnackBar(message, isError: isError);
  void reportError(Response response) => ApiChecker.checkApi(response);
  void openVerification(String countryCode, String number, VerificationForm form) =>
      Get.to(() => VerificationScreen(countryCode: countryCode, number: number, form: form));
  void openResetPassword(String phoneNumber) => Get.to(() => ResetPasswordScreen(phoneNumber: phoneNumber));
  void openHome({required bool zoneMissing, required dynamic profileBody}) {
    if (zoneMissing) {
      Get.offAll(() => const AccessLocationScreen());
    } else {
      Get.offAll(() => const DashboardScreen());
    }
    PusherHelper().driverTripRequestSubscribe(profileBody['data']['id']);
  }

  void showSignUpApproveDialog() {
    showDialog(
        context: Get.context!,
        builder: (_) => ApproveDialogWidget(
            icon: Images.waitForVerification,
            description: 'create_account_approve_description'.tr,
            title: 'registration_not_approve_yet'.tr,
            onYesPressed: () {
              Get.offAll(() => const SignInScreen());
            }),
        barrierDismissible: false);
  }
}

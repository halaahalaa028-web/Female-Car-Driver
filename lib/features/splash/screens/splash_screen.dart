import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/localization/language_selection_screen.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  final String? userName;
  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (!GetPlatform.isIOS) {
      _checkConnectivity();
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();
    _route();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkConnectivity() {
    bool isFirst = true;
    _onConnectivityChanged = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);
      if ((isFirst && !isConnected) || !isFirst && context.mounted) {
        ScaffoldMessenger.of(Get.context!).removeCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(
            isConnected ? 'connected'.tr : 'no_connection'.tr,
            textAlign: TextAlign.center,
          ),
        ));

        if (isConnected) {
          _route();
        }
      }
      isFirst = false;
    });
  }

  void _route() async {
    bool isSuccess = await Get.find<SplashController>().getConfigData();
    if (isSuccess) {
      if (Get.find<LocalizationController>().haveLocalLanguageCode()) {
        LoginHelper()
            .checkLoginRoutes(widget.notificationData, widget.userName);
      } else {
        Get.offAll(() => LanguageSelectionScreen(
            userName: widget.userName,
            notificationData: widget.notificationData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF030538)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(Images.logo, width: 200, height: 200),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Theme.of(context).primaryColor,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

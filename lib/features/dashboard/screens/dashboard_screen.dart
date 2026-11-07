import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/custom_asset_image_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/zoom_drawer_context_widget.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/domain/models/navigation_model.dart';
import 'package:ride_sharing_user_app/features/home/screens/home_screen.dart';
import 'package:ride_sharing_user_app/features/notification/screens/notification_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/trip_screen.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wallet_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    Get.find<RideController>().updateRoute(true);
    final List<NavigationModel> item = [
      NavigationModel(
          name: 'home'.tr,
          activeIcon: Images.homeActive,
          inactiveIcon: Images.homeOutline,
          screen: const HomeMenu()),
      NavigationModel(
          name: 'activity'.tr,
          activeIcon: Images.activityActive,
          inactiveIcon: Images.activityOutline,
          screen: const TripHistoryMenu()),
      NavigationModel(
          name: 'notification'.tr,
          activeIcon: Images.notificationActive,
          inactiveIcon: Images.notificationOutline,
          screen: const NotificationMenu()),
      NavigationModel(
          name: 'wallet'.tr,
          activeIcon: Images.moneyActive,
          inactiveIcon: Images.moneyOutline,
          screen: const WalletScreenMenu()),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (res, val) async {
        if (Get.find<BottomMenuController>().currentTab != 0) {
          if (Get.find<ProfileController>().toggle) {
            Get.find<ProfileController>().toggleDrawer();
            Get.find<BottomMenuController>().setTabIndex(0);
          } else {
            if (Get.find<BottomMenuController>().currentTab == 3) {
              if (Get.find<WalletController>().walletTypeIndex == 0) {
                Get.find<BottomMenuController>().setTabIndex(0);
              } else {
                Get.find<WalletController>().moveToPreviousProfileType();
              }
            } else {
              Get.find<BottomMenuController>().setTabIndex(0);
            }
          }
          return;
        } else {
          if (Get.find<ProfileController>().toggle) {
            Get.find<ProfileController>().toggleDrawer();
          } else {
            Get.find<BottomMenuController>().exitApp();
          }
          return;
        }
      },
      child: GetBuilder<BottomMenuController>(builder: (menuController) {
        return SafeArea(
          top: false,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(children: [
              PageStorage(
                  bucket: bucket,
                  child: item[menuController.currentTab].screen),
              Positioned(
                child: ValueListenableBuilder<bool>(
                  valueListenable: ZoomDrawerState.drawerVisible,
                  builder: (context, drawerVisible, child) =>
                      drawerVisible ? const SizedBox.shrink() : child!,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 36,
                        right: 36,
                        bottom: 12,
                      ),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 1,
                              color: Colors.black.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.35
                                    : 0.12,
                              ),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: generateBottomNavigationItems(
                            menuController,
                            item,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ]),
          ),
        );
      }),
    );
  }

  List<Widget> generateBottomNavigationItems(
    BottomMenuController menuController,
    List<NavigationModel> item,
  ) {
    List<Widget> items = [];
    for (int index = 0; index < item.length; index++) {
      items.add(
        Expanded(
          child: CustomMenuItem(
            isSelected: menuController.currentTab == index,
            name: item[index].name,
            activeIcon: item[index].activeIcon,
            inActiveIcon: item[index].inactiveIcon,
            onTap: () => menuController.setTabIndex(index),
          ),
        ),
      );
    }
    return items;
  }
}

class CustomMenuItem extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String activeIcon;
  final String inActiveIcon;
  final VoidCallback onTap;

  const CustomMenuItem({
    super.key,
    required this.isSelected,
    required this.name,
    required this.activeIcon,
    required this.inActiveIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color inactiveColor = Theme.of(context).hintColor;

    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: CustomAssetImageWidget(
                isSelected ? activeIcon : inActiveIcon,
                width: 20,
                height: 20,
                color: isSelected ? primaryColor : inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textMedium.copyWith(
              color: isSelected ? primaryColor : inactiveColor,
              fontSize: Dimensions.fontSizeExtraSmall,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

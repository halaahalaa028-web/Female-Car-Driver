import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/map_launcher_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';

import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';

class DriverHeaderInfoWidget extends StatelessWidget {
  const DriverHeaderInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideController>(builder: (rideController){
      return Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 60, Dimensions.paddingSizeDefault,0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Theme.of(context).primaryColor)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: ImageWidget(width: 50,height: 50,
                  image: '${Get.find<SplashController>().config!.imageBaseUrl!.profileImage}/${Get.find<ProfileController>().driverImage}',
                ),
              ),
            ),

            const Spacer(),

            if(_isShowNavigatorButton(rideController.tripDetail?.currentStatus))
              InkWell(
                onTap: () async {
                  final trip = rideController.tripDetail;
                  if (trip == null) return;

                  final bool isPickup = trip.currentStatus == 'accepted' || trip.currentStatus == 'pending';
                  final coords = isPickup
                      ? trip.pickupCoordinates?.coordinates
                      : trip.destinationCoordinates?.coordinates;

                  if (coords != null && coords.length >= 2) {
                    await MapLauncherHelper.openMap(
                      latitude: coords[1],
                      longitude: coords[0],
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                    boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha: .25), blurRadius: 1,spreadRadius: 1, offset: const Offset(0,1))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: SizedBox(width: Dimensions.iconSizeMedium, height: Dimensions.iconSizeMedium,
                      child: Image.asset(Images.navigation, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              )
          ],
        ),
      );
    });
  }

  bool _isShowNavigatorButton(String? currentStatus){
    if(currentStatus == 'accepted' || currentStatus == 'pending' || currentStatus == 'ongoing'){
      return true;
    }else{
      return false;
    }
  }

}

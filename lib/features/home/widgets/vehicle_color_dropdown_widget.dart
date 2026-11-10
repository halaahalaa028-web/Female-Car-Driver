import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class VehicleColorDropdownWidget extends StatelessWidget {
  const VehicleColorDropdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final String effectiveValue = AppConstants.carColors.contains(profileController.selectedCarColor)
            ? profileController.selectedCarColor
            : AppConstants.carColors.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFieldTitleWidget(title: 'car_color'.tr, isRequired: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  width: 0.7,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
              ),
              child: DropdownButton<String>(
                value: effectiveValue,
                items: AppConstants.carColors.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value.tr,
                      style: textRegular.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    profileController.setCarColor(value, true);
                  }
                },
                isExpanded: true,
                underline: const SizedBox(),
              ),
            ),
          ],
        );
      },
    );
  }
}

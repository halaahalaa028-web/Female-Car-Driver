import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class VehicleDocumentsSectionWidget extends StatelessWidget {
  const VehicleDocumentsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context: context,
              title: 'driving_license_documents'.tr,
              icon: Images.identity,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                Expanded(
                  child: _buildDocSlot(
                    context: context,
                    title: 'licence_image_front'.tr,
                    file: profileController.licenceFrontDoc,
                    onTap: () => profileController.pickVehicleDocumentSlot('licence_front'),
                    onRemove: () => profileController.removeVehicleDocumentSlot('licence_front'),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: _buildDocSlot(
                    context: context,
                    title: 'licence_image_back'.tr,
                    file: profileController.licenceBackDoc,
                    onTap: () => profileController.pickVehicleDocumentSlot('licence_back'),
                    onRemove: () => profileController.removeVehicleDocumentSlot('licence_back'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _buildSectionHeader(
              context: context,
              title: 'vehicle_exterior_photos'.tr,
              icon: Images.drivedIcon,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                Expanded(
                  child: _buildDocSlot(
                    context: context,
                    title: 'car_image_front'.tr,
                    file: profileController.carFrontDoc,
                    onTap: () => profileController.pickVehicleDocumentSlot('car_front'),
                    onRemove: () => profileController.removeVehicleDocumentSlot('car_front'),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: _buildDocSlot(
                    context: context,
                    title: 'car_image_back'.tr,
                    file: profileController.carBackDoc,
                    onTap: () => profileController.pickVehicleDocumentSlot('car_back'),
                    onRemove: () => profileController.removeVehicleDocumentSlot('car_back'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String icon,
  }) {
    return Row(
      children: [
        Image.asset(icon, height: 18, width: 18),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          title,
          style: textBold.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(
          '*',
          style: textBold.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildDocSlot({
    required BuildContext context,
    required String title,
    required PlatformFile? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null && file.path != null;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: hasFile
              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
              : Theme.of(context).hintColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          if (!hasFile)
            GestureDetector(
              onTap: onTap,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  strokeWidth: 1,
                  dashPattern: const [4, 4],
                  color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                  radius: const Radius.circular(Dimensions.paddingSizeSmall),
                ),
                child: Container(
                  height: 95,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    color: Theme.of(context).hintColor.withValues(alpha: 0.04),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Images.upload, height: 24, width: 24),
                      const SizedBox(height: 4),
                      Text(
                        'tap_to_upload'.tr,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                  child: Image.file(
                    File(file.path!),
                    height: 95,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: onRemove,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

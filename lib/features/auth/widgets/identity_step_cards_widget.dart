import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class IdentityStepCardsWidget extends StatelessWidget {
  const IdentityStepCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSlotCard(
              context: context,
              title: 'identity_image_front'.tr,
              subtitle: 'upload_front_side'.tr,
              imagePath: authController.identityFrontImage?.path,
              onTap: () => authController.pickIdentityImage(false),
              onRemove: () => authController.removeIdentityImage(false),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildSlotCard(
              context: context,
              title: 'identity_image_back'.tr,
              subtitle: 'upload_back_side'.tr,
              imagePath: authController.identityBackImage?.path,
              onTap: () => authController.pickIdentityImage(true),
              onRemove: () => authController.removeIdentityImage(true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlotCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String? imagePath,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: hasImage
              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(Images.identity, height: 16, width: 16),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                title,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                '*',
                style: textMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (!hasImage)
            GestureDetector(
              onTap: onTap,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  strokeWidth: 1,
                  dashPattern: const [5, 5],
                  color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                  radius: const Radius.circular(Dimensions.paddingSizeSmall),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Images.galleryIcon, height: 26, width: 26),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        subtitle,
                        style: textRegular.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      Text(
                        'tap_to_upload'.tr,
                        style: textRegular.copyWith(
                          color: Theme.of(context).hintColor,
                          fontSize: Dimensions.fontSizeExtraSmall,
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
                    File(imagePath),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
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
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 18,
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

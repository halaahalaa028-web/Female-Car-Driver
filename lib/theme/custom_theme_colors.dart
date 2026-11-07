import 'package:flutter/material.dart';

class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  final Color blackColor;
  final Color infoColor;
  final Color upComingTagColor;
  final Color warningBackGroundColor;

  const CustomThemeColors({
    required this.blackColor,
    required this.infoColor,
    required this.upComingTagColor,
    required this.warningBackGroundColor,
  });

  // Predefined themes for light and dark modes
  factory CustomThemeColors.light() => const CustomThemeColors(
    blackColor: Color(0xFF000000),
    infoColor: Color(0xFF0177CD),
    upComingTagColor: Color(0xFF5D40B2),
    warningBackGroundColor: Color(0xFFFFF1F1),
  );

  factory CustomThemeColors.dark() => const CustomThemeColors(
    blackColor: Color(0xFFFFFFFF),
    infoColor: Color(0xFF0177CD),
    upComingTagColor: Color(0xFF5D40B2),
    warningBackGroundColor: Color(0xFFFFF1F1),
  );

  @override
  CustomThemeColors copyWith({
    Color? blackColor,
    Color? infoColor,
    Color? upComingTagColor,
    Color? warningBackGroundColor,
  }) {
    return CustomThemeColors(
      blackColor: blackColor ?? this.blackColor,
      infoColor: infoColor ?? this.infoColor,
      upComingTagColor: upComingTagColor ?? this.upComingTagColor,
      warningBackGroundColor: warningBackGroundColor ?? this.warningBackGroundColor,
    );
  }

  @override
  CustomThemeColors lerp(ThemeExtension<CustomThemeColors>? other, double t) {
    if (other is! CustomThemeColors) return this;

    return CustomThemeColors(
      blackColor: Color.lerp(blackColor, other.blackColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      upComingTagColor: Color.lerp(upComingTagColor, other.upComingTagColor, t)!,
      warningBackGroundColor: Color.lerp(warningBackGroundColor, other.warningBackGroundColor, t)!,
    );
  }
}
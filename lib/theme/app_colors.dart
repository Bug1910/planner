import 'package:flutter/material.dart';

/// 日系無印風配色 v2 · 單色系 + 單一墨藍強調色
/// 靈感：MUJI、Kinfolk、Linear、Things 3
class AppColors {
  AppColors._();

  // 背景層（暖米白）
  static const Color background    = Color(0xFFF5EFE6);
  static const Color backgroundAlt = Color(0xFFEFE8DA);
  static const Color surface       = Color(0xFFFAF6EE); // 較背景亮 3%
  static const Color surfaceAlt    = Color(0xFFF0EAE0);
  static const Color divider       = Color(0xFFE8E0D3); // 暖色細線

  // 主色（墨藍 · 單一強調色）
  static const Color primary       = Color(0xFF2C3E5C);
  static const Color primaryDark   = Color(0xFF1B2B45);
  static const Color primarySoft   = Color(0xFFE4E8EE);
  static const Color onPrimary     = Color(0xFFFAF6EE);

  // 次色（淡抹茶 · 備用）
  static const Color accent        = Color(0xFF7B8F6B);
  static const Color accentSoft    = Color(0xFFE8EEDF);

  // 狀態色（降彩度）
  static const Color success       = Color(0xFF7B8F6B);
  static const Color warning       = Color(0xFFB8974E);
  static const Color warningSoft   = Color(0xFFF4EBD3);
  static const Color danger        = Color(0xFFB5685D);
  static const Color dangerSoft    = Color(0xFFF0D9D6);

  // 文字（暖調黑階）
  static const Color textPrimary   = Color(0xFF2B2724);
  static const Color textSecondary = Color(0xFF8A8178);
  static const Color textMuted     = Color(0xFFB5AC9E);
  static const Color textDisabled  = Color(0xFFD4CCBE);
  static const Color textOnPrimary = Color(0xFFFAF6EE);

  // 班別（降彩度 · 當左側色條用）
  static const Color shiftMorningBg   = Color(0xFFFBEFDC);
  static const Color shiftMorningText = Color(0xFF8B5D2A);
  static const Color shiftMorningDot  = Color(0xFFC88B52);

  static const Color shiftEveningBg   = Color(0xFFE4E8EE);
  static const Color shiftEveningText = Color(0xFF1B2B45);
  static const Color shiftEveningDot  = Color(0xFF2C3E5C);

  static const Color shiftOffBg   = Color(0xFFE8EEDF);
  static const Color shiftOffText = Color(0xFF4B5D3F);
  static const Color shiftOffDot  = Color(0xFF7B8F6B);

  // 陰影（極淡 · 不用描邊）
  static const Color shadowSoft   = Color(0x0D2B2724);
  static const Color shadowMedium = Color(0x162B2724);
}

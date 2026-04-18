import 'package:flutter/material.dart';

class R {
  static double _w = 390;
  static double _h = 844;
  static double _scale = 1.0;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width <= 0) return; // 避免寬度為 0 時初始化
    _w = size.width;
    _h = size.height;
    _scale = (_w / 390).clamp(0.7, 1.4);
  }

  static double get w => _w;
  static double get h => _h;

  // 字體大小
  static double fs(double size) => (size * _scale).clamp(size * 0.8, size * 1.3);

  // 間距 / padding / radius
  static double sp(double size) => size * _scale;

  // 圖示大小
  static double icon(double size) => (size * _scale).clamp(size * 0.85, size * 1.2);

  // 橫向佔比（0.0 ~ 1.0）
  static double pct(double percent) => _w * percent;
}

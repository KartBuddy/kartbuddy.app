import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  static double screenWidth(BuildContext context) {
    return 1.sw; // ScreenUtil width
  }

  static double screenHeight(BuildContext context) {
    return 1.sh; // ScreenUtil height
  }

  static bool isMobile(BuildContext context) {
    return 1.sw < 600;
  }

  static bool isTablet(BuildContext context) {
    return 1.sw >= 600 && 1.sw < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return 1.sw >= 1024;
  }

  // Responsive padding - uses ScreenUtil for scaling
  static EdgeInsets padding(BuildContext context) {
    if (isDesktop(context)) {
      return EdgeInsets.all(32.w);
    } else if (isTablet(context)) {
      return EdgeInsets.all(24.w);
    } else {
      return EdgeInsets.all(16.w);
    }
  }

  // Responsive font sizes - uses ScreenUtil for scaling
  static double fontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return (baseSize * 1.2).sp;
    } else if (isTablet(context)) {
      return (baseSize * 1.1).sp;
    } else {
      return baseSize.sp;
    }
  }

  // Responsive width percentage - uses ScreenUtil
  static double widthPercent(BuildContext context, double percent) {
    return (1.sw * (percent / 100));
  }

  // Responsive height percentage - uses ScreenUtil
  static double heightPercent(BuildContext context, double percent) {
    return (1.sh * (percent / 100));
  }

  // Get responsive max width for content
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200.w;
    } else if (isTablet(context)) {
      return 800.w;
    } else {
      return double.infinity;
    }
  }

  // Responsive spacing - uses ScreenUtil for scaling
  static double spacing(BuildContext context, double baseSpacing) {
    if (isDesktop(context)) {
      return (baseSpacing * 1.5).h;
    } else if (isTablet(context)) {
      return (baseSpacing * 1.2).h;
    } else {
      return baseSpacing.h;
    }
  }

  // Responsive icon size - uses ScreenUtil for scaling
  static double iconSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return (baseSize * 1.3).w;
    } else if (isTablet(context)) {
      return (baseSize * 1.15).w;
    } else {
      return baseSize.w;
    }
  }
}


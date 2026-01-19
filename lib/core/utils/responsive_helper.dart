import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  static const double _tabletBreakpoint =1240.0;
  static const double _tablet11InchWidth = 834.0;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _tabletBreakpoint;
  }

  static double getResponsiveWidth(BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static double getResponsiveHeight(BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static double getResponsiveRadius(BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static EdgeInsets getResponsivePadding(BuildContext context, {
    required EdgeInsets mobile,
    required EdgeInsets tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static double getResponsiveSpacing(BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static double rw(BuildContext context, double mobile, [double? tablet]) {
    return isTablet(context) ? (tablet ?? mobile * 0.5).w : mobile.w;
  }

  static double rh(BuildContext context, double mobile, [double? tablet]) {
    return isTablet(context) ? (tablet ?? mobile * 1.0).h : mobile.h;
  }

  static double rsp(BuildContext context, double mobile, [double? tablet]) {
    return isTablet(context) ? (tablet ?? mobile * 1.2).sp : mobile.sp;
  }

  static double rr(BuildContext context, double mobile, [double? tablet]) {
    return isTablet(context) ? (tablet ?? mobile * 1.4).r : mobile.r;
  }

  static EdgeInsets rPadding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
    double? tabletMultiplier,
  }) {
    final multiplier = tabletMultiplier ?? 1.5;
    final isTab = isTablet(context);

    if (all != null) {
      return EdgeInsets.all(isTab ? (all * multiplier).w : all.w);
    }

    return EdgeInsets.only(
      left: left != null
          ? (isTab ? (left * multiplier).w : left.w)
          : (horizontal != null ? (isTab ? (horizontal * multiplier).w : horizontal.w) : 0),
      right: right != null
          ? (isTab ? (right * multiplier).w : right.w)
          : (horizontal != null ? (isTab ? (horizontal * multiplier).w : horizontal.w) : 0),
      top: top != null
          ? (isTab ? (top * multiplier).h : top.h)
          : (vertical != null ? (isTab ? (vertical * multiplier).h : vertical.h) : 0),
      bottom: bottom != null
          ? (isTab ? (bottom * multiplier).h : bottom.h)
          : (vertical != null ? (isTab ? (vertical * multiplier).h : vertical.h) : 0),
    );
  }

  static SizedBox rVerticalSpace(BuildContext context, double mobile, [double? tablet]) {
    return SizedBox(height: rh(context, mobile, tablet));
  }

  static SizedBox rHorizontalSpace(BuildContext context, double mobile, [double? tablet]) {
    return SizedBox(width: rw(context, mobile, tablet));
  }
}

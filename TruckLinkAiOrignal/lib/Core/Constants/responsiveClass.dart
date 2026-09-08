import 'package:flutter/material.dart';

class Responsive {
  static double w(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double h(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => w(context) < 600;

  static bool isTablet(BuildContext context) =>
      w(context) >= 600 && w(context) < 1000;

  static bool isDesktop(BuildContext context) => w(context) >= 1000;
}
// Ignoring, will be removed in the future

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/icons.dart';

class ActivityIcon extends StatelessWidget {
  final String activity;
  final double size;

  const ActivityIcon({super.key, required this.activity, this.size = 32});

  @override
  Widget build(BuildContext context) {
    String asset;
    switch (activity) {
      case 'bike':
        asset = AppIcons.bike;
        break;
      case 'dumbbell':
        asset = AppIcons.dumbbell;
        break;
      default:
        asset = AppIcons.footprints;
    }
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

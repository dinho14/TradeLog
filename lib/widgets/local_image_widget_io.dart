import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

Widget buildLocalImageWidget(
  XFile image, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  return Image.file(
    File(image.path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppTheme.surfaceAlt,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppTheme.textMuted,
          ),
        ),
  );
}

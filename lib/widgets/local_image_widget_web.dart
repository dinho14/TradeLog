import 'dart:typed_data';

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
  return FutureBuilder<Uint8List>(
    future: image.readAsBytes(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Container(
          width: width,
          height: height,
          color: AppTheme.surfaceAlt,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        );
      }

      if (snapshot.hasError || snapshot.data == null) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: AppTheme.surfaceAlt,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppTheme.textMuted,
              ),
            );
      }

      return Image.memory(
        snapshot.data!,
        width: width,
        height: height,
        fit: fit,
      );
    },
  );
}

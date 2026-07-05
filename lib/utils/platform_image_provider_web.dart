import 'package:flutter/material.dart';

ImageProvider platformFileImageProvider(String fileUrl) {
  throw UnsupportedError('Local file images are not supported on web.');
}

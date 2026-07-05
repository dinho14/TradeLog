import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider platformFileImageProvider(String fileUrl) {
  final file = File(Uri.parse(fileUrl).toFilePath());
  return FileImage(file);
}

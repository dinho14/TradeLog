import 'dart:io';

Future<void> deleteLocalFilePath(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

String localPathFromUrl(String url) {
  if (url.startsWith('file://')) {
    return Uri.parse(url).toFilePath();
  }
  return url;
}

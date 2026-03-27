import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Returns a writable temp file path for saving a recording.
Future<String> nextTempRecordingPath() async {
  final dir = await getTemporaryDirectory();
  final ts = DateTime.now().millisecondsSinceEpoch;
  return '${dir.path}${Platform.pathSeparator}lecture_$ts.m4a';
}


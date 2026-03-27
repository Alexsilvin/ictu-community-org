import 'dart:io';
import 'dart:typed_data';

/// Reads bytes from a local file path (mobile/desktop).
Future<Uint8List> readFileBytes(String path) async {
  final data = await File(path).readAsBytes();
  return Uint8List.fromList(data);
}


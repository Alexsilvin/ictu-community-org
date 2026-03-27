import 'dart:typed_data';

/// Web does not have direct file path access. This is only used if someone
/// mistakenly calls uploadAudioFile on web.
Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Reading local file paths is not supported on web. Use uploadAudioBytes().');
}



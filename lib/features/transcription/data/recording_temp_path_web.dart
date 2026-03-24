/// Web does not provide a writable local file system path.
/// Recording is disabled in the UI for web.
Future<String> nextTempRecordingPath() {
  throw UnsupportedError('Recording temp path is not available on web');
}


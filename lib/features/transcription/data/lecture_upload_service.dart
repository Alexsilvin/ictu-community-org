import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'lecture_upload_service_io.dart'
    if (dart.library.html) 'lecture_upload_service_web.dart' as platform;

typedef JsonMap = Map<String, dynamic>;

class LectureUploadService {
  LectureUploadService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Uploads the audio file to Supabase Storage bucket `lecture-audio`.
  ///
  /// Returns the storage object path (bucket-relative) that must be passed as
  /// `audioUrl` to the `transcribe-audio` Edge Function.
  Future<String> uploadAudioFile({
    required dynamic file,
  }) async {
    // `file` is expected to be a String path on mobile/desktop.
    // We intentionally avoid importing dart:io in web builds.
    final String path = file is String ? file : file.toString();
    final fileName = path.split(RegExp(r'[/\\]')).last;

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You must be logged in to upload audio.');
    }

    final objectPath = 'lectures/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // Use uploadBinary for maximum compatibility where File types differ.
    // On mobile/desktop, Supabase accepts dart:io File, but we only have a path.
    // So we read bytes via platform file APIs at runtime.
    final bytes = await platform.readFileBytes(path);
    try {
      await _client.storage.from('lecture-audio').uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      // Surface policy/RLS issues clearly.
      throw Exception('Storage upload failed: ${e.message} (statusCode=${e.statusCode})');
    }

    return objectPath;
  }


  /// Web-friendly upload using in-memory bytes.
  ///
  /// Returns the storage object path (bucket-relative) that must be passed as
  /// `audioUrl` to the `transcribe-audio` Edge Function.
  Future<String> uploadAudioBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName.trim().isEmpty
        ? 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a'
        : fileName.trim();

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You must be logged in to upload audio.');
    }

    final objectPath =
        'lectures/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await _client.storage.from('lecture-audio').uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message} (statusCode=${e.statusCode})');
    }

    return objectPath;
  }

  /// Creates a lecture row and returns its id.
  ///
  /// This assumes your `lectures` table accepts at least these fields.
  Future<String> createLectureRow({
    required String audioPath,
    String? title,
    String? courseCode,
  }) async {
    final payload = <String, dynamic>{
      'audio_url': audioPath,
      // Backend schema requires course_code NOT NULL.
      // Use a best-effort value from UI, otherwise fall back to 'UNKNOWN'
      // so uploads/transcription are not blocked.
      'course_code': (courseCode != null && courseCode.trim().isNotEmpty)
          ? courseCode.trim()
          : 'UNKNOWN',
      // Use a conservative default compatible with common status CHECK
      // constraints (e.g. pending/processing/completed/failed).
      'status': 'pending',
    };

    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }

    final Map<String, dynamic> res;
    try {
      res = await _client
          .from('lectures')
          .insert(payload)
          .select('id')
          .single();
    } on PostgrestException catch (e) {
      throw Exception('Lectures insert failed: ${e.message} (code=${e.code})');
    }

    final id = res['id'];
    return id.toString();
  }
}


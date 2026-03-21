import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_instance.dart';

typedef JsonMap = Map<String, dynamic>;

class LectureUploadService {
  LectureUploadService({SupabaseClient? client})
      : _client = client ?? SupabaseInstance.client;

  final SupabaseClient _client;

  /// Uploads the audio file to Supabase Storage bucket `lecture-audio`.
  ///
  /// Returns the storage object path (bucket-relative) that must be passed as
  /// `audioUrl` to the `transcribe-audio` Edge Function.
  Future<String> uploadAudioFile({
    required File file,
  }) async {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

    final objectPath = 'lectures/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('lecture-audio').upload(
          objectPath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return objectPath;
  }

  /// Creates a lecture row and returns its id.
  ///
  /// This assumes your `lectures` table accepts at least these fields.
  Future<String> createLectureRow({
    required String audioPath,
    String? title,
  }) async {
    final payload = <String, dynamic>{
      'audio_url': audioPath,
      'status': 'queued',
    };

    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }

    final res = await _client
        .from('lectures')
        .insert(payload)
        .select('id')
        .single();

    final id = res['id'];
    return id.toString();
  }
}


import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

class TranscriptionApi {
  TranscriptionApi({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<JsonMap> transcribeAudio({
    required String lectureId,
    required String audioPath,
  }) async {
    final res = await _client.functions.invoke(
      'transcribe-audio',
      body: {
        'lectureId': lectureId,
        'audioUrl': audioPath, // Edge function expects a storage object path
      },
    );

    if (res.status != 200) {
      final err = _extractError(res.data);
      throw Exception(err ?? 'Transcription failed');
    }

    return _asJsonMap(res.data);
  }

  JsonMap _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      // Some functions return JSON string payloads.
      return jsonDecode(data) as JsonMap;
    }
    throw const FormatException('Unexpected response from server');
  }

  String? _extractError(dynamic data) {
    try {
      final map = _asJsonMap(data);
      final err = map['error'];
      return err is String ? err : err?.toString();
    } catch (_) {
      return null;
    }
  }
}



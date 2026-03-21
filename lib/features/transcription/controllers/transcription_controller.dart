import 'package:flutter/foundation.dart';

import '../data/transcription_repository.dart';

typedef JsonMap = Map<String, dynamic>;

class TranscriptionController {
  TranscriptionController({TranscriptionRepository? repository})
      : _repository = repository ?? TranscriptionRepository();

  final TranscriptionRepository _repository;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<JsonMap?> lastResult = ValueNotifier<JsonMap?>(null);

  Future<JsonMap?> transcribe({
    required String lectureId,
    required String audioPath,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final res = await _repository.transcribeAudio(
        lectureId: lectureId,
        audioPath: audioPath,
      );
      lastResult.value = res;
      return res;
    } catch (e) {
      errorMessage.value = e.toString();
      lastResult.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    lastResult.dispose();
  }
}


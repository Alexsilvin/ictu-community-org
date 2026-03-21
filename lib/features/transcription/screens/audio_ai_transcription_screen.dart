import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../controllers/transcription_controller.dart';
import '../data/lecture_upload_service.dart';

class AudioAiTranscriptionScreen extends StatelessWidget {
  const AudioAiTranscriptionScreen({super.key});

  static const Color _bg = Color(0xFF0A0C10);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Audio/AI Transcription',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(52),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _DashboardTabBar(),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _RecordTab(),
            _UploadTab(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTabBar extends StatelessWidget {
  const _DashboardTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0x91D49100), Color(0x9114154C)],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        tabs: const [
          Tab(text: 'Record'),
          Tab(text: 'Upload'),
        ],
      ),
    );
  }
}

enum _RecordUiState {
  idle,
  recording,
  paused,
  stopped,
}

class _RecordTab extends StatefulWidget {
  const _RecordTab();

  @override
  State<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<_RecordTab> with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFF58220);
  static const Color _glass = Color(0xFF0A0C10);

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  final TextEditingController _courseCodeController = TextEditingController();

  _RecordUiState _state = _RecordUiState.idle;
  Timer? _timer;
  int _elapsedSeconds = 0;

  String? _recordedPath;
  String? _recordedName;
  int _recordedBytes = 0;
  Duration _recordedDuration = Duration.zero;

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  double _speed = 1.0;

  String? _error;
  String? _warning;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _total = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _position = Duration.zero;
        _playerState = PlayerState.stopped;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _courseCodeController.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double _estimatedBytes(int durationSeconds) {
    // as specified: duration * 16000 / 8 bytes
    return durationSeconds * 16000 / 8;
  }

  String _formatBytes(num bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 1) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _nextTempPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}lecture_$ts.m4a';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;

        final estimate = _estimatedBytes(_elapsedSeconds);
        _warning = null;
        _error = null;
        if (estimate > 15 * 1024 * 1024 && estimate <= 20 * 1024 * 1024) {
          _warning = 'Recording is getting large (~${_formatBytes(estimate)}).';
        }
        if (estimate > 20 * 1024 * 1024) {
          _error = 'Recording too large (>20MB). Stopping.';
        }
      });

      if (_error != null && _state == _RecordUiState.recording) {
        unawaited(_stopRecording());
      }
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
      _warning = null;
    });

    final ok = await _ensureMicPermission();
    if (!ok) {
      setState(() => _error = 'Microphone permission is required to record.');
      return;
    }

    final path = await _nextTempPath();

    // Stop player if it was playing a previous recording.
    await _player.stop();
    _position = Duration.zero;
    _total = Duration.zero;

    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 64000,
    );

    await _recorder.start(config, path: path);

    setState(() {
      _state = _RecordUiState.recording;
      _elapsedSeconds = 0;
      _recordedPath = path;
      _recordedName = path.split(Platform.pathSeparator).last;
      _recordedBytes = 0;
      _recordedDuration = Duration.zero;
      _resultReset();
    });

    _pulseController.repeat(reverse: true);
    _startTimer();
  }

  void _resultReset() {
    // placeholder for future expansion
  }

  Future<void> _pauseRecording() async {
    if (_state != _RecordUiState.recording) return;
    await _recorder.pause();
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _state = _RecordUiState.paused);
  }

  Future<void> _resumeRecording() async {
    if (_state != _RecordUiState.paused) return;
    await _recorder.resume();
    setState(() => _state = _RecordUiState.recording);
    _pulseController.repeat(reverse: true);
    _startTimer();
  }

  Future<void> _stopRecording() async {
    if (!await _recorder.isRecording()) {
      // Might be paused but not recording
      if (_state != _RecordUiState.paused) {
        return;
      }
    }

    _timer?.cancel();
    _pulseController.stop();

    final path = await _recorder.stop();
    final realPath = path ?? _recordedPath;

    if (realPath == null) {
      setState(() {
        _state = _RecordUiState.idle;
        _error = 'Could not finalize recording.';
      });
      return;
    }

    final f = File(realPath);
    final bytes = await f.length();
    final duration = Duration(seconds: _elapsedSeconds);

    setState(() {
      _recordedPath = realPath;
      _recordedName = realPath.split(Platform.pathSeparator).last;
      _recordedBytes = bytes;
      _recordedDuration = duration;
      _state = _RecordUiState.stopped;
      _position = Duration.zero;
      _total = duration;
    });

    if (bytes > 20 * 1024 * 1024) {
      setState(() => _error = 'Recording is larger than 20MB (${_formatBytes(bytes)}).');
    } else if (bytes > 15 * 1024 * 1024) {
      setState(() => _warning = 'Recording is large (${_formatBytes(bytes)}).');
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    try {
      await _recorder.stop();
    } catch (_) {}

    // Delete temp file if created.
    final p = _recordedPath;
    if (p != null) {
      final f = File(p);
      if (await f.exists()) {
        await f.delete();
      }
    }

    setState(() {
      _state = _RecordUiState.idle;
      _elapsedSeconds = 0;
      _recordedPath = null;
      _recordedName = null;
      _recordedBytes = 0;
      _recordedDuration = Duration.zero;
      _position = Duration.zero;
      _total = Duration.zero;
      _error = null;
      _warning = null;
    });
  }

  Future<void> _togglePlay() async {
    final path = _recordedPath;
    if (path == null) return;

    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    if (_playerState == PlayerState.paused) {
      await _player.resume();
      return;
    }

    await _player.setPlaybackRate(_speed);
    await _player.play(DeviceFileSource(path));
  }

  Future<void> _seek(Duration d) async {
    await _player.seek(d);
  }

  Future<void> _setSpeed(double s) async {
    setState(() => _speed = s);
    await _player.setPlaybackRate(s);
  }

  void _continueToUpload() {
    // Requirement allows switching tab.
    DefaultTabController.of(context).animateTo(1);
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimateBytes = _estimatedBytes(_elapsedSeconds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        const _SectionTitle('Record Audio'),
        const SizedBox(height: 14),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0x1AF87171),
              border: Border.all(color: const Color(0x33F87171)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_warning != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0x1AF59E0B),
              border: Border.all(color: const Color(0x33F59E0B)),
            ),
            child: Text(
              _warning!,
              style: const TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_state == _RecordUiState.idle) ...[
          Center(
            child: GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AF58220),
                  border: Border.all(color: const Color(0x33F58220), width: 2),
                ),
                child: const Icon(Icons.mic_rounded, size: 48, color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Code',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _courseCodeController,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., ICTU 210',
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _accent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Tips'),
          const SizedBox(height: 12),
          const _GlassTile(
            title: 'Record in a quiet place',
            subtitle: 'Background noise reduces transcription quality.',
            leadingIcon: Icons.tips_and_updates_rounded,
          ),
          const SizedBox(height: 12),
          const _GlassTile(
            title: 'Keep phone close to speaker',
            subtitle: '1–2 meters is usually best.',
            leadingIcon: Icons.hearing_rounded,
          ),
          const SizedBox(height: 12),
          const _GlassTile(
            title: 'Avoid very long recordings',
            subtitle: 'Try to keep files under 15MB for faster processing.',
            leadingIcon: Icons.timelapse_rounded,
          ),
        ],

        if (_state == _RecordUiState.recording || _state == _RecordUiState.paused) ...[
          const SizedBox(height: 8),
          Center(
            child: _state == _RecordUiState.recording
                ? ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x33EF4444),
                        border: Border.all(color: const Color(0xFFEF4444), width: 2),
                      ),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1AF58220),
                      border: Border.all(color: const Color(0x33F58220), width: 2),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _mmss(_elapsedSeconds),
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontWeight: FontWeight.w800,
                fontSize: 48,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '~${_formatBytes(estimateBytes)}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  data: _ActionCardData(
                    icon: _state == _RecordUiState.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_circle_filled_rounded,
                    title: _state == _RecordUiState.paused ? 'Resume' : 'Pause',
                    subtitle: _state == _RecordUiState.paused
                        ? 'Continue recording'
                        : 'Temporarily pause',
                    tint: const Color(0x1AF58220),
                    border: const Color(0x33F58220),
                    iconColor: const Color(0xFFF58220),
                  ),
                  onTap: _state == _RecordUiState.paused ? _resumeRecording : _pauseRecording,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  data: const _ActionCardData(
                    icon: Icons.stop_circle_rounded,
                    title: 'Stop',
                    subtitle: 'Finish recording',
                    tint: Color(0x08FFFFFF),
                    border: Color(0x14FFFFFF),
                    iconColor: Color(0xFF94A3B8),
                  ),
                  onTap: _stopRecording,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: _cancelRecording,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],

        if (_state == _RecordUiState.stopped) ...[
          _GlassTile(
            title: _recordedName ?? 'lecture.m4a',
            subtitle:
                '${_mmss(_recordedDuration.inSeconds)} • ${_formatBytes(_recordedBytes)}',
            leadingIcon: Icons.multitrack_audio_rounded,
          ),
          const SizedBox(height: 14),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x1AF58220),
                          border: Border.all(color: const Color(0x33F58220), width: 2),
                        ),
                        child: Icon(
                          _playerState == PlayerState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _accent,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _accent,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
                              thumbColor: _accent,
                            ),
                            child: Slider(
                              min: 0,
                              max: (_total.inMilliseconds > 0)
                                  ? _total.inMilliseconds.toDouble()
                                  : (_recordedDuration.inMilliseconds.toDouble()),
                              value: _position.inMilliseconds
                                  .clamp(0, (_total.inMilliseconds > 0 ? _total.inMilliseconds : _recordedDuration.inMilliseconds))
                                  .toDouble(),
                              onChanged: (v) => _seek(Duration(milliseconds: v.round())),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _mmss(_position.inSeconds),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _mmss((_total == Duration.zero
                                        ? _recordedDuration
                                        : _total)
                                    .inSeconds),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _SpeedChip(
                      label: '0.5x',
                      selected: _speed == 0.5,
                      onTap: () => _setSpeed(0.5),
                    ),
                    _SpeedChip(
                      label: '1x',
                      selected: _speed == 1.0,
                      onTap: () => _setSpeed(1.0),
                    ),
                    _SpeedChip(
                      label: '1.5x',
                      selected: _speed == 1.5,
                      onTap: () => _setSpeed(1.5),
                    ),
                    _SpeedChip(
                      label: '2x',
                      selected: _speed == 2.0,
                      onTap: () => _setSpeed(2.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  data: const _ActionCardData(
                    icon: Icons.replay_rounded,
                    title: 'Re-record',
                    subtitle: 'Discard and record again',
                    tint: Color(0x08FFFFFF),
                    border: Color(0x14FFFFFF),
                    iconColor: Color(0xFF94A3B8),
                  ),
                  onTap: _cancelRecording,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  data: const _ActionCardData(
                    icon: Icons.north_east_rounded,
                    title: 'Continue',
                    subtitle: 'Go to upload & transcribe',
                    tint: Color(0x1AF58220),
                    border: Color(0x33F58220),
                    iconColor: Color(0xFFF58220),
                  ),
                  onTap: _continueToUpload,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? const Color(0x1AF58220)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: selected
                ? const Color(0x33F58220)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFF58220) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  @override
  Widget build(BuildContext context) {
    return const _UploadTabStateful();
  }
}

class _UploadTabStateful extends StatefulWidget {
  const _UploadTabStateful();

  @override
  State<_UploadTabStateful> createState() => _UploadTabStatefulState();
}

class _UploadTabStatefulState extends State<_UploadTabStateful> {
  final LectureUploadService _uploadService = LectureUploadService();
  final TranscriptionController _controller = TranscriptionController();

  File? _selectedFile;
  String? _selectedName;
  int? _selectedBytes;
  String? _lectureId;
  String? _audioPath;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    setState(() {
      _error = null;
      _result = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      withData: false,
    );

    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;

    final picked = res.files.first;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      setState(() => _error = 'Could not read the selected file path.');
      return;
    }

    setState(() {
      _selectedFile = File(path);
      _selectedName = picked.name;
      _selectedBytes = picked.size;
      _lectureId = null;
      _audioPath = null;
    });
  }

  Future<void> _uploadAndTranscribe() async {
    if (_selectedFile == null) {
      setState(() => _error = 'Pick an audio file first.');
      return;
    }

    setState(() {
      _error = null;
      _result = null;
    });

    try {
      // 1) Upload
      final audioPath = await _uploadService.uploadAudioFile(file: _selectedFile!);
      // 2) Create lecture row (so we have a lectureId for the edge function)
      final lectureId = await _uploadService.createLectureRow(
        audioPath: audioPath,
        title: _selectedName,
      );

      setState(() {
        _audioPath = audioPath;
        _lectureId = lectureId;
      });

      // 3) Invoke edge function
      final payload = await _controller.transcribe(
        lectureId: lectureId,
        audioPath: audioPath,
      );

      if (!mounted) return;
      if (payload == null) {
        setState(() => _error = _controller.errorMessage.value ?? 'Transcription failed');
        return;
      }

      setState(() {
        _result = payload;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        const _SectionTitle('Upload Audio'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                data: const _ActionCardData(
                  icon: Icons.upload_file_rounded,
                  title: 'Pick Audio File',
                  subtitle: 'mp3, m4a, wav…',
                  tint: Color(0x08FFFFFF),
                  border: Color(0x14FFFFFF),
                  iconColor: Color(0xFF94A3B8),
                ),
                onTap: _pickAudio,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoading,
                builder: (context, loading, _) {
                  return _ActionCard(
                    data: _ActionCardData(
                      icon: Icons.auto_awesome_rounded,
                      title: loading ? 'Working…' : 'Transcribe',
                      subtitle: loading
                          ? 'Uploading & transcribing'
                          : (_selectedFile == null ? 'Pick a file first' : 'Send to AI'),
                      tint: const Color(0x1AF58220),
                      border: const Color(0x33F58220),
                      iconColor: const Color(0xFFF58220),
                    ),
                    onTap: loading ? null : _uploadAndTranscribe,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Queue'),
        const SizedBox(height: 12),

        if (_selectedFile != null)
          _GlassTile(
            title: _selectedName ?? 'Selected audio',
            subtitle: 'Selected • ${_formatBytes(_selectedBytes)}',
            leadingIcon: Icons.queue_music_rounded,
          )
        else
          _GlassTile(
            title: 'No file selected',
            subtitle: 'Pick an audio file to begin',
            leadingIcon: Icons.queue_music_rounded,
          ),

        if (_audioPath != null) ...[
          const SizedBox(height: 12),
          _GlassTile(
            title: 'Uploaded',
            subtitle: _audioPath!,
            leadingIcon: Icons.cloud_done_rounded,
          ),
        ],
        if (_lectureId != null) ...[
          const SizedBox(height: 12),
          _GlassTile(
            title: 'Lecture ID',
            subtitle: _lectureId!,
            leadingIcon: Icons.tag_rounded,
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0x1AF87171),
              border: Border.all(color: const Color(0x33F87171)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],

        if (_result != null) ...[
          const SizedBox(height: 18),
          const _SectionTitle('Result'),
          const SizedBox(height: 12),
          _GlassTile(
            title: ((_result!['data'] as Map?)?['transcription_result'] as Map?)?['title']
                    ?.toString() ??
                'Transcription ready',
            subtitle: ((_result!['data'] as Map?)?['summary'] as String?) ?? 'Summary available',
            leadingIcon: Icons.check_circle_rounded,
          ),
        ],
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_ActionCardData> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionCard(data: actions[0])),
        const SizedBox(width: 14),
        Expanded(child: _ActionCard(data: actions[1])),
      ],
    );
  }
}

class _ActionCardData {
  const _ActionCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.border,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color border;
  final Color iconColor;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data, this.onTap});

  final _ActionCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: data.tint,
            border: Border.all(color: data.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              leadingIcon,
              color: Colors.white.withValues(alpha: 0.75),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -0.25,
      ),
    );
  }
}



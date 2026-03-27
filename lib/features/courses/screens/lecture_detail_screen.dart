import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../widgets/course_ui.dart';

class LectureDetailScreen extends StatefulWidget {
  const LectureDetailScreen({
    super.key,
    required this.course,
    required this.lecture,
  });

  final Course course;
  final CourseLecture lecture;

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  Duration _position = Duration.zero;
  final Duration _total = const Duration(minutes: 52);
  bool _playing = false;
  double _speed = 1.0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _timer?.cancel();
    if (_playing) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          final next = _position + const Duration(seconds: 1);
          _position = next > _total ? _total : next;
          if (_position >= _total) {
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  void _seek(Duration d) {
    setState(() {
      if (d < Duration.zero) return;
      _position = d > _total ? _total : d;
    });
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;

    return Scaffold(
      backgroundColor: CourseUi.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.85)),
        ),
        title: Text(
          lecture.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share not wired yet.')),
              );
            },
            icon: Icon(Icons.share_rounded, color: Colors.white.withValues(alpha: 0.85)),
          ),
          IconButton(
            tooltip: 'Download',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download not wired yet.')),
              );
            },
            icon: Icon(Icons.download_rounded, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0x33F59E0B), Color(0x1AF58220)],
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Transcript'),
                  Tab(text: 'Assignments'),
                  Tab(text: 'Resources'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SummaryTab(),
                _TranscriptTab(),
                _AssignmentsTab(),
                _ResourcesTab(),
              ],
            ),
          ),
          _BottomPlayer(
            playing: _playing,
            position: _position,
            total: _total,
            speed: _speed,
            onTogglePlay: _togglePlay,
            onSeek: _seek,
            onSpeedChanged: (v) => setState(() => _speed = v),
            onExpand: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _ExpandedPlayer(
                  playing: _playing,
                  position: _position,
                  total: _total,
                  speed: _speed,
                  onTogglePlay: _togglePlay,
                  onSeek: _seek,
                  onSpeedChanged: (v) => setState(() => _speed = v),
                ),
              );
            },
            mmss: _mmss,
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: CourseUi.glassCard(radius: 18),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI summary', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text(
                'This lecture introduces the core concepts and builds intuition with real examples. It also highlights common pitfalls and what to focus on for the next assignment.',
                style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35),
              ),
              SizedBox(height: 14),
              Text('Key points', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('• What the topic is and why it matters', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              Text('• Typical exam/CA patterns', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              Text('• Best practices and mistakes to avoid', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Topics covered', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...List<Widget>.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: CourseUi.glassCard(radius: 18),
            child: ExpansionTile(
              collapsedIconColor: Colors.white.withValues(alpha: 0.75),
              iconColor: Colors.white.withValues(alpha: 0.75),
              title: Text(
                'Topic ${i + 1}',
                style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: const [
                Text(
                  'Short explanation with examples and what you should remember.',
                  style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptTab extends StatefulWidget {
  const _TranscriptTab();

  @override
  State<_TranscriptTab> createState() => _TranscriptTabState();
}

class _TranscriptTabState extends State<_TranscriptTab> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _search,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: CourseUi.searchDecoration(hint: 'Search transcript...'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: CourseUi.glassCard(radius: 18),
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: const [
                Text(
                  'Full transcript will appear here. You can scroll, search, and copy text.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Color(0x14FFFFFF)),
            foregroundColor: CourseUi.text,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          ),
          onPressed: null,
          child: Text('Copy text (coming soon)', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab();

  @override
  Widget build(BuildContext context) {
    Widget card({required Color tint, required String title, required String subtitle}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: tint,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        card(
          tint: const Color(0x1AF87171),
          title: 'Assignment mentioned',
          subtitle: 'Deadline: Friday 11:59 PM\nBuild a mini project and submit all required files.',
        ),
        card(
          tint: const Color(0x1AF59E0B),
          title: 'CA mentioned',
          subtitle: 'Deadline: Next week Monday\nQuiz covers lectures 1–4.',
        ),
      ],
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: CourseUi.glassCard(radius: 18),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resources', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('• Book: Clean Code (Robert C. Martin)', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              Text('• Link: https://flutter.dev', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 14),
              Text('Action items', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('• Review the key points', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              Text('• Start the assignment early', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 14),
              Text('Important definitions', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('• Definition 1: ...', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomPlayer extends StatelessWidget {
  const _BottomPlayer({
    required this.playing,
    required this.position,
    required this.total,
    required this.speed,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onExpand,
    required this.mmss,
  });

  final bool playing;
  final Duration position;
  final Duration total;
  final double speed;
  final VoidCallback onTogglePlay;
  final void Function(Duration) onSeek;
  final void Function(double) onSpeedChanged;
  final VoidCallback onExpand;
  final String Function(Duration) mmss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: CourseUi.glassCard(radius: 22),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onTogglePlay,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x1AF58220),
                        border: Border.all(color: const Color(0x33F58220)),
                      ),
                      child: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: CourseUi.accent,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: CourseUi.accent,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
                            thumbColor: CourseUi.accent,
                          ),
                          child: Slider(
                            min: 0,
                            max: total.inMilliseconds.toDouble(),
                            value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                            onChanged: (v) => onSeek(Duration(milliseconds: v.round())),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(mmss(position), style: const TextStyle(color: CourseUi.muted, fontSize: 11, fontWeight: FontWeight.w800)),
                            Text(mmss(total), style: const TextStyle(color: CourseUi.muted, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SpeedMenu(speed: speed, onChanged: onSpeedChanged),
                  IconButton(
                    tooltip: 'Expand',
                    onPressed: onExpand,
                    icon: Icon(Icons.expand_less_rounded, color: Colors.white.withValues(alpha: 0.8)),
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

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.speed, required this.onChanged});

  final double speed;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      color: const Color(0xFF111726),
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          '${speed}x',
          style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0.5, child: Text('0.5x', style: TextStyle(color: CourseUi.text))),
        PopupMenuItem(value: 1.0, child: Text('1x', style: TextStyle(color: CourseUi.text))),
        PopupMenuItem(value: 1.5, child: Text('1.5x', style: TextStyle(color: CourseUi.text))),
        PopupMenuItem(value: 2.0, child: Text('2x', style: TextStyle(color: CourseUi.text))),
      ],
    );
  }
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer({
    required this.playing,
    required this.position,
    required this.total,
    required this.speed,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSpeedChanged,
  });

  final bool playing;
  final Duration position;
  final Duration total;
  final double speed;
  final VoidCallback onTogglePlay;
  final void Function(Duration) onSeek;
  final void Function(double) onSpeedChanged;

  String _mmss(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: CourseUi.glassCard(radius: 24),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Player', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: onTogglePlay,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1AF58220),
                      border: Border.all(color: const Color(0x33F58220)),
                    ),
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: CourseUi.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: CourseUi.accent,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
                          thumbColor: CourseUi.accent,
                        ),
                        child: Slider(
                          min: 0,
                          max: total.inMilliseconds.toDouble(),
                          value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                          onChanged: (v) => onSeek(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_mmss(position), style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w800)),
                          Text(_mmss(total), style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SpeedMenu(speed: speed, onChanged: onSpeedChanged),
          ],
        ),
      ),
    );
  }
}



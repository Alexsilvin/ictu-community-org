import 'package:flutter/material.dart';

import '../data/mock_course_repository.dart';
import '../models/course_models.dart';
import '../utils/course_time_utils.dart';
import '../widgets/course_ui.dart';
import 'alert_detail_screen.dart';
import 'lecture_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.repo,
    required this.courseId,
  });

  final MockCourseRepository repo;
  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  Course? _course;
  bool _loading = true;

  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final course = await widget.repo.getCourseById(widget.courseId);
    if (!mounted) return;
    setState(() {
      _course = course;
      _loading = false;
    });
  }

  Future<void> _toggleBookmark() async {
    await widget.repo.toggleBookmark(widget.courseId);
    await _load();
  }

  Future<void> _unEnroll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111726),
          title: const Text('Unenroll', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
          content: const Text(
            'Are you sure you want to unenroll from this course?',
            style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: CourseUi.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Unenroll', style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await widget.repo.unenroll(widget.courseId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;

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
          course?.code ?? 'Course',
          style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Bookmark',
            onPressed: course == null ? null : _toggleBookmark,
            icon: Icon(
              (course?.isBookmarked ?? false) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: (course?.isBookmarked ?? false) ? CourseUi.accent : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF111726),
            iconColor: Colors.white.withValues(alpha: 0.85),
            onSelected: (v) {
              if (v == 'unenroll') {
                _unEnroll();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report sent. Thank you.')),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report issue', style: TextStyle(color: CourseUi.text))),
              PopupMenuItem(value: 'unenroll', child: Text('Unenroll', style: TextStyle(color: Color(0xFFF87171)))),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            alignment: Alignment.centerLeft,
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
                  Tab(text: 'Lectures'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Alerts'),
                  Tab(text: 'Announcements'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: CourseUi.accent),
            )
          : (course == null
              ? const Center(
                  child: Text('Course not found', style: TextStyle(color: CourseUi.text)),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                        children: [
                          _Header(course: course),
                          const SizedBox(height: 14),
                          _Stats(course: course),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 520,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _LecturesTab(course: course, repo: widget.repo),
                                _NotesTab(course: course),
                                _AlertsTab(course: course, repo: widget.repo),
                                _AnnouncementsTab(course: course),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x33F87171)),
                            foregroundColor: const Color(0xFFF87171),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _unEnroll,
                          child: const Text(
                            'Unenroll from Course',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CourseUi.glassCard(radius: 20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // Lecturer profile view not implemented, keep as toast.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open lecturer profile: ${course.lecturerName}')),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CourseUi.accent, width: 2),
                  ),
                  child: CircleAvatar(backgroundImage: AssetImage(course.lecturerPhotoAsset)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    course.lecturerName,
                    style: const TextStyle(
                      color: CourseUi.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            course.description,
            style: const TextStyle(color: CourseUi.muted, height: 1.35, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Last accessed: ${timeAgo(course.lastAccessed)}',
            style: const TextStyle(color: CourseUi.muted2, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Lectures', '${course.totalLectures}'),
        const SizedBox(width: 10),
        chip('Notes', '5'),
        const SizedBox(width: 10),
        chip('Active Alerts', '${course.unreadAlerts}'),
      ],
    );
  }
}

class _LecturesTab extends StatelessWidget {
  const _LecturesTab({required this.course, required this.repo});

  final Course course;
  final MockCourseRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseLecture>>(
      future: repo.listLectures(course.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: CourseUi.accent));
        }
        final lectures = snap.data!;
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: lectures.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final l = lectures[i];
            return Container(
              decoration: CourseUi.glassCard(radius: 18),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LectureDetailScreen(course: course, lecture: l),
                    ),
                  );
                },
                title: Text(
                  l.title,
                  style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                subtitle: Text(
                  'Lecture ${l.lectureNumber} • ${l.duration.inMinutes} min',
                  style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, fontSize: 11),
                ),
                trailing: Icon(
                  l.isWatched ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                  color: l.isWatched ? const Color(0xFF22C55E) : CourseUi.accent,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CourseUi.glassCard(radius: 18),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Notes will appear here.\n\nTip: Upload lecture audio via the Transcription feature to generate summaries and key points.',
        style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.course, required this.repo});

  final Course course;
  final MockCourseRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseAlert>>(
      future: repo.listAlerts(course.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: CourseUi.accent));
        }
        final alerts = snap.data!;
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: alerts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = alerts[i];
            return Container(
              decoration: CourseUi.glassCard(radius: 18),
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AlertDetailScreen(alert: a),
                    ),
                  );
                },
                title: Text(
                  a.title,
                  style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                subtitle: Text(
                  dueInText(a.deadline),
                  style: TextStyle(
                    color: a.deadline.isBefore(DateTime.now()) ? const Color(0xFFF87171) : CourseUi.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.7)),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CourseUi.glassCard(radius: 18),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Announcements will appear here.',
        style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700),
      ),
    );
  }
}


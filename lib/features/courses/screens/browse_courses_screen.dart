import 'package:flutter/material.dart';

import '../data/mock_course_repository.dart';
import '../models/course_models.dart';
import '../widgets/course_cards.dart';
import '../widgets/course_ui.dart';

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({
    super.key,
    required this.repo,
    required this.onOpenCourse,
  });

  final MockCourseRepository repo;
  final void Function(Course course) onOpenCourse;

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final TextEditingController _search = TextEditingController();

  String _faculty = 'All';
  bool _enrolledOnly = false;

  bool _loading = true;
  List<Course> _courses = const <Course>[];

  static const List<String> _faculties = <String>[
    'All',
    'Computing',
    'Business',
    'Engineering',
    'Arts',
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _search
      ..removeListener(_load)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await widget.repo.listAllCourses(
      query: _search.text,
      faculty: _faculty,
      showEnrolledOnly: _enrolledOnly,
    );
    if (!mounted) return;
    setState(() {
      _courses = items;
      _loading = false;
    });
  }

  Future<void> _confirmEnroll(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111726),
          title: const Text(
            'Enroll',
            style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Enroll in ${course.code} • ${course.title}?',
            style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: CourseUi.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enroll', style: TextStyle(color: CourseUi.accent, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await widget.repo.enroll(course.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enrolled in ${course.code}')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CourseUi.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.85)),
          ),
          title: const Text(
            'Browse Courses',
            style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        body: RefreshIndicator(
          color: CourseUi.accent,
          backgroundColor: const Color(0xFF111726),
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
            children: [
              TextField(
                controller: _search,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: CourseUi.searchDecoration(hint: 'Search by name or code...'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _faculty,
                          dropdownColor: const Color(0xFF111726),
                          iconEnabledColor: Colors.white.withValues(alpha: 0.7),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          items: _faculties
                              .map((f) => DropdownMenuItem<String>(
                                    value: f,
                                    child: Text(f),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _faculty = v);
                            _load();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Enrolled only',
                            style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          const Spacer(),
                          Switch(
                            value: _enrolledOnly,
                            activeTrackColor: CourseUi.accent,
                            onChanged: (v) {
                              setState(() => _enrolledOnly = v);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                ...List<Widget>.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 84,
                    decoration: CourseUi.glassCard(radius: 18),
                  ),
                )
              else
                ..._courses.map(
                  (c) => CourseBrowseCard(
                    course: c,
                    onTap: () => widget.onOpenCourse(c),
                    onEnroll: c.isEnrolled ? () {} : () => _confirmEnroll(c),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


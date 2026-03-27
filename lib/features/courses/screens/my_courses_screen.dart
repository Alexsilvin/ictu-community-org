import 'package:flutter/material.dart';

import '../data/mock_course_repository.dart';
import '../models/course_models.dart';
import '../widgets/course_cards.dart';
import '../widgets/course_ui.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({
    super.key,
    required this.repo,
    required this.onOpenCourse,
    this.onBrowse,
  });

  final MockCourseRepository repo;
  final void Function(Course course) onOpenCourse;
  final VoidCallback? onBrowse;

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  bool _loading = true;
  List<Course> _courses = const <Course>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final courses = await widget.repo.listMyCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
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
          centerTitle: true,
          leading: const SizedBox(width: 56),
          title: const Text(
            'My Courses',
            style: TextStyle(
              color: CourseUi.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () {},
              icon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.85)),
            ),
            IconButton(
              tooltip: 'Browse',
              onPressed: widget.onBrowse,
              icon: Icon(Icons.grid_view_rounded, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: CourseUi.accent,
          backgroundColor: const Color(0xFF111726),
          onRefresh: _load,
          child: _loading
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    _SkeletonCard(),
                    SizedBox(height: 12),
                    _SkeletonCard(),
                  ],
                )
              : (_courses.isEmpty
                  ? _EmptyState(onBrowse: widget.onBrowse)
                  : _Grid(courses: _courses, onOpen: widget.onOpenCourse)),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.courses, required this.onOpen});

  final List<Course> courses;
  final void Function(Course course) onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.84,
      ),
      itemCount: courses.length,
      itemBuilder: (context, i) => CourseGridCard(
        course: courses[i],
        onTap: () => onOpen(courses[i]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'No courses yet',
          style: TextStyle(
            color: CourseUi.text,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enroll in a course from the catalog to start tracking progress and alerts.',
          style: TextStyle(
            color: CourseUi.muted,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), CourseUi.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onBrowse,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Center(
                  child: Text(
                    'Browse Courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: CourseUi.glassCard(radius: 18),
    );
  }
}


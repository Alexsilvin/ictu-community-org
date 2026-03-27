import 'package:flutter/material.dart';

import '../data/mock_course_repository.dart';
import '../models/course_models.dart';
import 'browse_courses_screen.dart';
import 'course_detail_screen.dart';
import 'my_courses_screen.dart';

/// Main Courses tab screen.
///
/// NOTE: This intentionally does NOT create a second bottom navigation bar.
/// It relies on the app-level [MainShell] bottom navigation.
class CourseTrackerScreen extends StatefulWidget {
  const CourseTrackerScreen({super.key});

  @override
  State<CourseTrackerScreen> createState() => _CourseTrackerScreenState();
}

class _CourseTrackerScreenState extends State<CourseTrackerScreen> {
  late final MockCourseRepository _repo = MockCourseRepository();

  void _openCourseDetail(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailScreen(repo: _repo, courseId: course.id),
      ),
    );
  }

  void _openBrowse() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrowseCoursesScreen(
          repo: _repo,
          onOpenCourse: _openCourseDetail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyCoursesScreen(
      repo: _repo,
      onOpenCourse: _openCourseDetail,
      onBrowse: _openBrowse,
    );
  }
}



import 'dart:math';

import '../models/course_models.dart';

class MockCourseRepository {
  MockCourseRepository();

  final Random _rand = Random(1);

  // In-memory state (so enroll/bookmark persists while app is running).
  late final List<Course> _courses = <Course>[
    Course(
      id: 'c1',
      code: 'SWE-402',
      title: 'Software Engineering',
      faculty: 'Computing',
      lecturerName: 'Prof. Dr. Victor Mbarika',
      lecturerPhotoAsset: 'assets/students.jpg',
      description:
          'Learn software processes, design patterns, requirements, testing and agile practices.',
      studentsCount: 312,
      isEnrolled: true,
      lecturesWatched: 18,
      totalLectures: 25,
      unreadAlerts: 3,
      lastAccessed: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Course(
      id: 'c2',
      code: 'CSC-315',
      title: 'Database Management',
      faculty: 'Computing',
      lecturerName: 'Dr. Sarah Johnson',
      lecturerPhotoAsset: 'assets/madam.jpg',
      description:
          'Relational databases, normalization, SQL, indexing, transactions, and query optimization.',
      studentsCount: 228,
      isEnrolled: true,
      lecturesWatched: 7,
      totalLectures: 12,
      unreadAlerts: 0,
      lastAccessed: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    Course(
      id: 'c3',
      code: 'MOB-210',
      title: 'Mobile Development',
      faculty: 'Computing',
      lecturerName: 'Eng. Deborah Mensah',
      lecturerPhotoAsset: 'assets/students.jpg',
      description:
          'Build cross-platform mobile apps with Flutter. UI, state management, APIs and deployment.',
      studentsCount: 189,
      isEnrolled: false,
      lecturesWatched: 0,
      totalLectures: 16,
      unreadAlerts: 1,
    ),
    Course(
      id: 'c4',
      code: 'BUS-101',
      title: 'Business Communication',
      faculty: 'Business',
      lecturerName: 'Mrs. Esther Adu',
      lecturerPhotoAsset: 'assets/madam.jpg',
      description:
          'Professional writing, presentations, workplace communication, and team collaboration.',
      studentsCount: 415,
      isEnrolled: false,
      lecturesWatched: 0,
      totalLectures: 10,
      unreadAlerts: 0,
    ),
  ];

  final Map<String, List<CourseLecture>> _lecturesByCourseId = <String, List<CourseLecture>>{};
  final Map<String, List<CourseAlert>> _alertsByCourseId = <String, List<CourseAlert>>{};

  Future<List<Course>> listAllCourses({
    String query = '',
    String? faculty,
    bool showEnrolledOnly = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    var items = _courses;

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      items = items
          .where((c) => c.title.toLowerCase().contains(q) || c.code.toLowerCase().contains(q))
          .toList();
    }

    if (faculty != null && faculty.trim().isNotEmpty && faculty != 'All') {
      items = items.where((c) => c.faculty == faculty).toList();
    }

    if (showEnrolledOnly) {
      items = items.where((c) => c.isEnrolled).toList();
    }

    return items;
  }

  Future<List<Course>> listMyCourses() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _courses.where((c) => c.isEnrolled).toList();
  }

  Future<Course?> getCourseById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> enroll(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    if (_courses[index].isEnrolled) return;
    _courses[index] = _courses[index].copyWith(isEnrolled: true, lastAccessed: DateTime.now());
  }

  Future<void> unenroll(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    _courses[index] = _courses[index].copyWith(isEnrolled: false);
  }

  Future<void> toggleBookmark(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    _courses[index] = _courses[index].copyWith(isBookmarked: !_courses[index].isBookmarked);
  }

  Future<List<CourseLecture>> listLectures(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _lecturesByCourseId.putIfAbsent(courseId, () {
      final courseIndex = _courses.indexWhere((c) => c.id == courseId);
      final total = courseIndex == -1 ? 10 : (_courses[courseIndex].totalLectures == 0 ? 10 : _courses[courseIndex].totalLectures);
      return List<CourseLecture>.generate(total, (i) {
        final num = i + 1;
        return CourseLecture(
          id: 'l-$courseId-$num',
          courseId: courseId,
          lectureNumber: num,
          title: 'Lecture $num • Topic ${(num % 5) + 1}',
          duration: Duration(minutes: 38 + _rand.nextInt(24)),
          isWatched: courseIndex != -1 && num <= _courses[courseIndex].lecturesWatched,
        );
      });
    });

    return _lecturesByCourseId[courseId]!;
  }

  Future<List<CourseAlert>> listAlerts(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _alertsByCourseId.putIfAbsent(courseId, () {
      final now = DateTime.now();
      return <CourseAlert>[
        CourseAlert(
          id: 'a-$courseId-1',
          courseId: courseId,
          title: 'Assignment 2: Build a mini project',
          type: CourseAlertType.assignment,
          deadline: now.add(const Duration(days: 2, hours: 5)),
          description:
              'Submit your mini project with documentation and screenshots. Late submissions incur penalty.',
          requirements: const [
            'GitHub repository link',
            'README with setup instructions',
            'Short demo video (optional)',
          ],
          attachments: const ['assignment2.pdf'],
          relatedLectureNumber: 5,
        ),
        CourseAlert(
          id: 'a-$courseId-2',
          courseId: courseId,
          title: 'CA Quiz: Week 4',
          type: CourseAlertType.ca,
          deadline: now.add(const Duration(days: 6)),
          description:
              'In-class quiz covering lectures 1–4. Bring your student ID card.',
          requirements: const ['Student ID', 'Pen/pencil'],
          attachments: const [],
        ),
      ];
    });

    return _alertsByCourseId[courseId]!;
  }
}


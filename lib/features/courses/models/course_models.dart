import 'package:flutter/material.dart';

@immutable
class Course {
  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.faculty,
    required this.lecturerName,
    required this.lecturerPhotoAsset,
    required this.description,
    required this.studentsCount,
    this.isEnrolled = false,
    this.isBookmarked = false,
    this.lecturesWatched = 0,
    this.totalLectures = 0,
    this.unreadAlerts = 0,
    this.lastAccessed,
  });

  final String id;
  final String code;
  final String title;
  final String faculty;

  final String lecturerName;
  final String lecturerPhotoAsset;
  final String description;

  final int studentsCount;

  final bool isEnrolled;
  final bool isBookmarked;

  final int lecturesWatched;
  final int totalLectures;
  final int unreadAlerts;

  /// When the user last opened the course.
  final DateTime? lastAccessed;

  double get progress => totalLectures == 0 ? 0 : (lecturesWatched / totalLectures);

  Course copyWith({
    bool? isEnrolled,
    bool? isBookmarked,
    int? lecturesWatched,
    int? totalLectures,
    int? unreadAlerts,
    DateTime? lastAccessed,
  }) {
    return Course(
      id: id,
      code: code,
      title: title,
      faculty: faculty,
      lecturerName: lecturerName,
      lecturerPhotoAsset: lecturerPhotoAsset,
      description: description,
      studentsCount: studentsCount,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lecturesWatched: lecturesWatched ?? this.lecturesWatched,
      totalLectures: totalLectures ?? this.totalLectures,
      unreadAlerts: unreadAlerts ?? this.unreadAlerts,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

@immutable
class CourseLecture {
  const CourseLecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.duration,
    required this.isWatched,
    required this.lectureNumber,
  });

  final String id;
  final String courseId;
  final String title;
  final Duration duration;
  final bool isWatched;
  final int lectureNumber;
}

enum CourseAlertType { assignment, ca, exam, announcement }

@immutable
class CourseAlert {
  const CourseAlert({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.deadline,
    required this.description,
    this.requirements = const <String>[],
    this.attachments = const <String>[],
    this.relatedLectureNumber,
    this.isDone = false,
  });

  final String id;
  final String courseId;
  final String title;
  final CourseAlertType type;
  final DateTime deadline;
  final String description;
  final List<String> requirements;
  final List<String> attachments;
  final int? relatedLectureNumber;
  final bool isDone;

  CourseAlert copyWith({bool? isDone}) {
    return CourseAlert(
      id: id,
      courseId: courseId,
      title: title,
      type: type,
      deadline: deadline,
      description: description,
      requirements: requirements,
      attachments: attachments,
      relatedLectureNumber: relatedLectureNumber,
      isDone: isDone ?? this.isDone,
    );
  }
}


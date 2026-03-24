import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../utils/course_time_utils.dart';
import 'course_ui.dart';

class CourseGridCard extends StatelessWidget {
  const CourseGridCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: CourseUi.glassCard(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1AF58220),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x33F58220)),
                    ),
                    child: Text(
                      course.code,
                      style: const TextStyle(
                        color: CourseUi.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  UnreadBadge(count: course.unreadAlerts),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CourseUi.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: course.progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation<Color>(CourseUi.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${course.lecturesWatched}/${course.totalLectures} lectures watched',
                style: const TextStyle(
                  color: CourseUi.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Last accessed: ${timeAgo(course.lastAccessed)}',
                style: const TextStyle(
                  color: CourseUi.muted2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseBrowseCard extends StatelessWidget {
  const CourseBrowseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onEnroll,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: CourseUi.glassCard(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0x1AF58220),
                    border: Border.all(color: const Color(0x33F58220)),
                  ),
                  child: Center(
                    child: Text(
                      course.code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CourseUi.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: CourseUi.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.lecturerName,
                        style: const TextStyle(
                          color: CourseUi.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${course.studentsCount} students',
                        style: const TextStyle(
                          color: CourseUi.muted2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _EnrollButton(
                  isEnrolled: course.isEnrolled,
                  onEnroll: onEnroll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnrollButton extends StatelessWidget {
  const _EnrollButton({required this.isEnrolled, required this.onEnroll});

  final bool isEnrolled;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    if (isEnrolled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Text(
          'Enrolled',
          style: TextStyle(
            color: CourseUi.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onEnroll,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF58220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Enroll',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../utils/course_time_utils.dart';
import '../widgets/course_ui.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key, required this.alert});

  final CourseAlert alert;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  late bool _done = widget.alert.isDone;

  Color _typeColor(CourseAlertType t) {
    switch (t) {
      case CourseAlertType.assignment:
        return const Color(0xFFF87171);
      case CourseAlertType.ca:
        return const Color(0xFFF59E0B);
      case CourseAlertType.exam:
        return const Color(0xFF38BDF8);
      case CourseAlertType.announcement:
        return const Color(0xFF22C55E);
    }
  }

  String _typeText(CourseAlertType t) {
    switch (t) {
      case CourseAlertType.assignment:
        return 'Assignment';
      case CourseAlertType.ca:
        return 'CA';
      case CourseAlertType.exam:
        return 'Exam';
      case CourseAlertType.announcement:
        return 'Announcement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final overdue = a.deadline.isBefore(DateTime.now());
    final typeColor = _typeColor(a.type);

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
          a.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: typeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _typeText(a.type).toUpperCase(),
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6),
                ),
              ),
              const Spacer(),
              Icon(Icons.flag_rounded, color: Colors.white.withValues(alpha: 0.35)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: CourseUi.glassCard(radius: 20),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deadline', style: TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  '${a.deadline}',
                  style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  dueInText(a.deadline),
                  style: TextStyle(
                    color: overdue ? const Color(0xFFF87171) : CourseUi.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: CourseUi.glassCard(radius: 20),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  a.description,
                  style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
            ),
          ),
          if (a.requirements.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: CourseUi.glassCard(radius: 20),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Requirements', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...a.requirements.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_box_outline_blank_rounded, color: Colors.white.withValues(alpha: 0.6), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(color: CourseUi.muted, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (a.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: CourseUi.glassCard(radius: 20),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attachments', style: TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...a.attachments.map(
                    (att) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, color: CourseUi.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(att, style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w800)),
                          ),
                          Icon(Icons.download_rounded, color: Colors.white.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionPill(
                icon: Icons.calendar_month_rounded,
                label: 'Add to Calendar',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calendar integration coming soon.')),
                  );
                },
              ),
              _ActionPill(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon.')),
                  );
                },
              ),
              _ActionPill(
                icon: _done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                label: _done ? 'Done' : 'Mark as done',
                onTap: () => setState(() => _done = !_done),
              ),
            ],
          ),
          if (a.relatedLectureNumber != null) ...[
            const SizedBox(height: 18),
            Container(
              decoration: CourseUi.glassCard(radius: 20),
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Open Lecture ${a.relatedLectureNumber} (link wiring coming soon).')),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: CourseUi.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This was mentioned in Lecture ${a.relatedLectureNumber}',
                        style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CourseUi.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: CourseUi.text, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


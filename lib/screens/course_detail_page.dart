import 'package:flutter/material.dart';
import '../services/learning_service.dart';
import '../widgets/badge_popup.dart';
import 'lesson_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final learningService = LearningService();
  List<Map<String, dynamic>> lessons = [];
  Set<int> completedLessons = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData({bool checkBadge = false}) async {
    final fetchedLessons =
        await learningService.getLessons(widget.course['id']);
    final progress = await learningService.getUserProgress(widget.course['id']);
    final completed = progress
        .where((p) => p['completed'] == true)
        .map<int>((p) => p['lesson_id'] as int)
        .toSet();

    debugPrint('checkBadge: $checkBadge');
    debugPrint('completed: ${completed.length}');
    debugPrint('total lessons: ${fetchedLessons.length}');

    if (!mounted) return;
    setState(() {
      lessons = fetchedLessons;
      completedLessons = completed;
      isLoading = false;
    });

    if (checkBadge &&
        completed.length == fetchedLessons.length &&
        fetchedLessons.isNotEmpty) {
      final alreadyHasBadge =
          await learningService.hasBadge(widget.course['id']);
      if (!alreadyHasBadge && mounted) {
        final badge =
            await learningService.getBadgeForCourse(widget.course['id']);
        if (badge != null) {
          await learningService.awardBadge(
            widget.course['id'],
            badge['name'],
            badge['description'],
          );
          if (mounted) {
            _showBadgePopup(badge['name'], badge['description'], badge);
          }
        }
      }
    }
  }

  void _showBadgePopup(
      String name, String description, Map<String, dynamic> badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => BadgePopup(
        badgeName: name,
        badgeDescription: description,
        icon: badge['icon'] ?? '⭐',
        colorPrimary: badge['color_primary'] ?? '#4CAF50',
        colorSecondary: badge['color_secondary'] ?? '#2E7D32',
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.course['total_lessons'] as int;
    final completed = completedLessons.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.course['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course['description'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$completed/$total completed',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final isDone = completedLessons.contains(lesson['id']);
                      final isLocked = index > 0 &&
                          !completedLessons.contains(lessons[index - 1]['id']);

                      return GestureDetector(
                        onTap: isLocked
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LessonPage(
                                      lesson: lesson,
                                      courseId: widget.course['id'],
                                      isCompleted: isDone,
                                    ),
                                  ),
                                );
                                loadData(checkBadge: true);
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFFF0F0F0)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isLocked
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.07),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFF2E7D32)
                                      : isLocked
                                          ? Colors.grey.shade300
                                          : const Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone
                                      ? Icons.check
                                      : isLocked
                                          ? Icons.lock_outline
                                          : Icons.play_arrow_rounded,
                                  color: isDone
                                      ? Colors.white
                                      : isLocked
                                          ? Colors.grey
                                          : const Color(0xFF2E7D32),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Step ${lesson['order']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isLocked
                                            ? Colors.grey
                                            : const Color(0xFF66BB6A),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      lesson['title'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked
                                            ? Colors.grey
                                            : const Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isDone)
                                const Text('Done',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

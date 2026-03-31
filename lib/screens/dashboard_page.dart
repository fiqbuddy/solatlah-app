import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/learning_service.dart';
import '../services/profile_service.dart';
import 'course_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onGoToLearn;
  const DashboardPage({super.key, this.onGoToLearn});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final learningService = LearningService();
  final profileService = ProfileService();

  String name = '';
  int totalCompleted = 0;
  int totalLessons = 0;
  int totalBadges = 0;
  int totalClasses = 3; // placeholder
  Map<String, dynamic>? recentCourse;
  int recentCourseCompleted = 0;
  List<Map<String, dynamic>> recentBadges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await profileService.getProfile();
      debugPrint('Profile: $profile');

      final courses = await learningService.getCourses();
      debugPrint('Courses: ${courses.length}');

      final total = await learningService.getTotalCompleted();
      debugPrint('Total completed: $total');

      final badges = await learningService.getTotalBadges();
      debugPrint('Total badges: $badges');

      final recent = await learningService.getRecentCourse();
      debugPrint('Recent course: $recent');

      final recentBadgeList = await learningService.getRecentBadges();
      debugPrint('Recent badges: ${recentBadgeList.length}');

      int tLessons = 0;
      for (final c in courses) {
        tLessons += (c['total_lessons'] as int);
      }

      int recentCompleted = 0;
      if (recent != null) {
        recentCompleted = await learningService.getCompletedCount(recent['id']);
      }

      if (!mounted) return;
      setState(() {
        name = profile?['name'] ?? 'Sahabat';
        totalCompleted = total;
        totalLessons = tLessons;
        totalBadges = badges;
        recentCourse = recent;
        recentCourseCompleted = recentCompleted;
        recentBadges = recentBadgeList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress =
        totalLessons == 0 ? 0.0 : totalCompleted / totalLessons;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : CustomScrollView(
              slivers: [
                // Top greeting header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 20,
                      right: 20,
                      bottom: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assalamualaikum,',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white30, width: 1.5),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Stat cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          label: 'Pembelajaran',
                          value:
                              '${(overallProgress * 100).toStringAsFixed(0)}%',
                          icon: Icons.auto_graph,
                          color: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 28, 39, 136),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Lencana',
                          value: '$totalBadges',
                          icon: Icons.military_tech,
                          color: Colors.white,
                          backgroundColor: const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Kelas',
                          value: '$totalClasses',
                          icon: Icons.groups,
                          color: Colors.white,
                          backgroundColor: const Color(0xFF6A1B9A),
                        ),
                      ],
                    ),
                  ),
                ),

                // Continue learning
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Teruskan Pembelajaran',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        // Lihat Semua button
                        GestureDetector(
                          onTap: widget.onGoToLearn,
                          child: const Text(
                            'Lihat Semua →',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent course card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: recentCourse == null
                        ? _EmptyCard(
                            icon: Icons.menu_book_rounded,
                            message: 'Belum ada pembelajaran.\nMula sekarang!',
                            onTap: widget.onGoToLearn,
                          )
                        : _RecentCourseCard(
                            course: recentCourse!,
                            completed: recentCourseCompleted,
                            onContinue: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CourseDetailPage(course: recentCourse!),
                              ),
                            ).then((_) => _loadData()),
                          ),
                  ),
                ),

                // Recent badges
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: const Text(
                      'Lencana Terkini',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: recentBadges.isEmpty
                        ? _EmptyCard(
                            icon: Icons.military_tech,
                            message:
                                'Belum ada lencana.\nSiapkan kursus untuk dapatkan lencana!',
                            onTap: null,
                          )
                        : Row(
                            children: recentBadges.asMap().entries.map((e) {
                              final badge = e.value;
                              final badgeData = badge['badges'];
                              final primary = badgeData != null
                                  ? _hexToColor(badgeData['color_primary'])
                                  : const Color(0xFF2E7D32);
                              final secondary = badgeData != null
                                  ? _hexToColor(badgeData['color_secondary'])
                                  : const Color(0xFF1B5E20);
                              final icon = badgeData?['icon'] ?? '⭐';

                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: e.key < recentBadges.length - 1
                                          ? 10
                                          : 0),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [primary, secondary],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withOpacity(0.4),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(icon,
                                              style: const TextStyle(
                                                  fontSize: 24)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        badge['badge_name'],
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recent course card
class _RecentCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final int completed;
  final VoidCallback onContinue;

  const _RecentCourseCard({
    required this.course,
    required this.completed,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final total = course['total_lessons'] as int;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed/$total pelajaran',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Teruskan Pelajaran',
                  style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// Empty state card
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onTap;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFB2DFDB), size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

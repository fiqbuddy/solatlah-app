import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LearningService {
  final client = Supabase.instance.client;
  String get currentEmail => client.auth.currentUser!.email!;

  Future<List<Map<String, dynamic>>> getCourses() async {
    return await client.from('courses').select().order('id', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getLessons(int courseId) async {
    return await client
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('order', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getUserProgress(int courseId) async {
    return await client
        .from('user_progress')
        .select()
        .eq('email', currentEmail)
        .eq('course_id', courseId);
  }

  Future<int> getCompletedCount(int courseId) async {
    final data = await client
        .from('user_progress')
        .select()
        .eq('email', currentEmail)
        .eq('course_id', courseId)
        .eq('completed', true);
    return data.length;
  }

  Future<int> getTotalCompleted() async {
    final data = await client
        .from('user_progress')
        .select()
        .eq('email', currentEmail)
        .eq('completed', true);
    return data.length;
  }

  Future<bool> isLessonCompleted(int lessonId) async {
    final data = await client
        .from('user_progress')
        .select()
        .eq('email', currentEmail)
        .eq('lesson_id', lessonId)
        .eq('completed', true)
        .maybeSingle();
    return data != null;
  }

  Future<void> completeLesson(int lessonId, int courseId) async {
    await client.from('user_progress').upsert({
      'email': currentEmail,
      'lesson_id': lessonId,
      'course_id': courseId,
      'completed': true,
    }, onConflict: 'email,lesson_id');
  }

  Future<List<Map<String, dynamic>>> getLessonAudios(int lessonId) async {
    return await client
        .from('lesson_audios')
        .select()
        .eq('lesson_id', lessonId)
        .order('order', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getLessonNiat(int lessonId) async {
    return await client
        .from('lesson_niat')
        .select()
        .eq('lesson_id', lessonId)
        .order('order', ascending: true);
  }

  Future<bool> hasBadge(int courseId) async {
    final data = await client
        .from('user_badges')
        .select()
        .eq('email', currentEmail)
        .eq('course_id', courseId)
        .maybeSingle();
    return data != null;
  }

  Future<void> awardBadge(
      int courseId, String badgeName, String badgeDescription) async {
    await client.from('user_badges').upsert({
      'email': currentEmail,
      'course_id': courseId,
      'badge_name': badgeName,
      'badge_description': badgeDescription,
    }, onConflict: 'email,course_id');
  }

  Future<List<Map<String, dynamic>>> getUserBadges() async {
    return await client
        .from('user_badges')
        .select()
        .eq('email', currentEmail)
        .order('earned_at');
  }

  Future<Map<String, dynamic>?> getBadgeForCourse(int courseId) async {
    return await client
        .from('badges')
        .select()
        .eq('course_id', courseId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getLessonQuestions(int lessonId) async {
    return await client
        .from('lesson_questions')
        .select()
        .eq('lesson_id', lessonId)
        .order('order', ascending: true);
  }

  Future<Map<String, dynamic>?> getRecentCourse() async {
    final data = await client
        .from('user_progress')
        .select()
        .eq('email', currentEmail)
        .eq('completed', true)
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();

    debugPrint('Recent progress row: $data');
    if (data == null) return null;

    final course = await client
        .from('courses')
        .select()
        .eq('id', data['course_id'])
        .maybeSingle();

    debugPrint('Recent course found: $course');
    return course;
  }

  Future<List<Map<String, dynamic>>> getRecentBadges() async {
    // Get user badges first
    final userBadges = await client
        .from('user_badges')
        .select()
        .eq('email', currentEmail)
        .order('earned_at', ascending: false)
        .limit(3);

    // Then fetch badge details for each
    final List<Map<String, dynamic>> result = [];
    for (final ub in userBadges) {
      final badge = await client
          .from('badges')
          .select()
          .eq('course_id', ub['course_id'])
          .maybeSingle();
      result.add({
        ...ub,
        'badges': badge,
      });
    }
    return result;
  }

  Future<int> getTotalBadges() async {
    final data =
        await client.from('user_badges').select().eq('email', currentEmail);
    return data.length;
  }
}

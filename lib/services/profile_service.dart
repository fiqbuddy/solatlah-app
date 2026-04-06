import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final client = Supabase.instance.client;
  Map<String, dynamic>? _cachedProfile; // cache

  String get currentEmail => client.auth.currentUser!.email!;

  Future<Map<String, dynamic>?> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile; // return cache instantly
    final response = await client
        .from('profiles')
        .select()
        .eq('email', currentEmail)
        .maybeSingle();
    _cachedProfile = response;
    return _cachedProfile;
  }

  Future<void> upsertProfile({
    required String name,
    required String phone,
    required String gender,
    DateTime? dob,
  }) async {
    final data = {
      'email': currentEmail,
      'name': name,
      'phone': phone,
      'gender': gender,
    };
    if (dob != null) {
      data['date_of_birth'] = dob.toIso8601String().split('T')[0];
    }
    await client.from('profiles').upsert(data, onConflict: 'email');
    _cachedProfile = null;
  }

  bool get isKid {
    final profile = _cachedProfile;
    if (profile == null || profile['date_of_birth'] == null) return false;
    final dob = DateTime.parse(profile['date_of_birth']);
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return age < 13;
  }
}

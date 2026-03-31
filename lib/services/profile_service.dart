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
  }) async {
    await client.from('profiles').upsert({
      'email': currentEmail,
      'name': name,
      'phone': phone,
      'gender': gender,
    }, onConflict: 'email');
    _cachedProfile = null; // clear cache after update so it reloads fresh
  }
}

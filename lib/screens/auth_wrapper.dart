import 'package:flutter/material.dart';
import 'package:solatlah_app/screens/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const MainScreen();
    } else {
      return const LoginPage();
    }
  }
}

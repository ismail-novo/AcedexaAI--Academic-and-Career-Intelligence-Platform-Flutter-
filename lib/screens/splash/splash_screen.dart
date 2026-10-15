import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    final user = AuthService().currentUser;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            user == null ? const LoginScreen() : const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6), Color(0xFF00BFA6)],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: Colors.white),

            SizedBox(height: 20),

            Text(
              'Acadexa AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Learn. Improve. Decide. Grow.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;

  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    setState(() => loading = true);

    try {
      await _authService.resetPassword(emailController.text);
      if (!mounted) return;
      _showMessage('Password reset email sent. Check your inbox.');
      Navigator.pop(context);
    } on Exception catch (_) {
      _showMessage('Failed to send reset email. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
              const SizedBox(height: 30),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we will send you a password reset link.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 35),
              AppTextField(
                controller: emailController,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: 'Send Reset Link',
                loading: loading,
                onPressed: _resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

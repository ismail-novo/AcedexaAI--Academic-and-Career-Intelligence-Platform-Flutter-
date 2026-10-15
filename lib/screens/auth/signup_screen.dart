import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_model.dart';

import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final studentIdController = TextEditingController();
  final universityController = TextEditingController();
  final departmentController = TextEditingController();
  final programController = TextEditingController();
  final semesterController = TextEditingController();
  final batchController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool loading = false;

  Future<void> _signup() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        studentIdController.text.trim().isEmpty ||
        universityController.text.trim().isEmpty ||
        departmentController.text.trim().isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (passwordController.text.length < 6) {
      _showMessage('Password must contain at least 6 characters.');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await _authService.signUp(
        email: emailController.text,
        password: passwordController.text,
      );

      final uid = credential.user!.uid;

      final student = StudentModel(
        uid: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        studentId: studentIdController.text.trim(),
        university: universityController.text.trim(),
        faculty: '',
        department: departmentController.text.trim(),
        program: programController.text.trim(),
        semester: semesterController.text.trim(),
        year: '',
        batch: batchController.text.trim(),
        graduationYear: '',
        cgpa: 0.0,
        careerGoal: '',
        targetRoles: [],
        interests: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createStudent(student);
      // Mark the account active and remember it in this device's account
      // list so it shows up correctly (with 0% stats) in Manage Accounts.
      await _firestoreService.updateStudent(uid, {'status': 'active'});
      await _authService.registerNewAccountOnDevice(
        uid: uid,
        email: emailController.text.trim(),
        name: nameController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('Account created successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on Exception catch (e) {
      _showMessage('Signup failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    studentIdController.dispose();
    universityController.dispose();
    departmentController.dispose();
    programController.dispose();
    semesterController.dispose();
    batchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Build Your Intelligence Profile',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tell Acadexa a little about yourself.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              AppTextField(
                controller: nameController,
                label: 'Full Name *',
                hint: 'Your name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: emailController,
                label: 'Email *',
                hint: 'example@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: passwordController,
                label: 'Password *',
                hint: 'Minimum 6 characters',
                icon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: studentIdController,
                label: 'Student ID *',
                hint: 'Your student ID',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: universityController,
                label: 'University *',
                hint: 'Your university',
                icon: Icons.account_balance_outlined,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: departmentController,
                label: 'Department *',
                hint: 'CSE / EEE / ME / BBA...',
                icon: Icons.school_outlined,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: programController,
                label: 'Program',
                hint: 'B.Sc / BBA / B.A...',
                icon: Icons.menu_book_outlined,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: semesterController,
                label: 'Semester',
                hint: 'Example: 7th',
                icon: Icons.calendar_month_outlined,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: batchController,
                label: 'Batch',
                hint: 'Example: 12',
                icon: Icons.groups_outlined,
              ),

              const SizedBox(height: 30),

              PrimaryButton(
                text: 'Create Account',
                loading: loading,
                onPressed: _signup,
              ),

              const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

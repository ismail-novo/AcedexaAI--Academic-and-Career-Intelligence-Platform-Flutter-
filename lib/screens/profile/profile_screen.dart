import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/student_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  StudentModel? student;
  bool loading = true;
  bool saving = false;
  bool editing = false;
  File? _photo;
  String? _photoUrl; // persisted network URL

  late TextEditingController nameCtrl;
  late TextEditingController studentIdCtrl;
  late TextEditingController universityCtrl;
  late TextEditingController departmentCtrl;
  late TextEditingController programCtrl;
  late TextEditingController semesterCtrl;
  late TextEditingController batchCtrl;
  late TextEditingController cgpaCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    studentIdCtrl = TextEditingController();
    universityCtrl = TextEditingController();
    departmentCtrl = TextEditingController();
    programCtrl = TextEditingController();
    semesterCtrl = TextEditingController();
    batchCtrl = TextEditingController();
    cgpaCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final result = await _firestoreService.getStudent(uid);
      if (mounted) {
        setState(() {
          student = result;
          loading = false;
          _photo = null; // prefer network URL after reload
          if (result != null) {
            nameCtrl.text = result.name;
            studentIdCtrl.text = result.studentId;
            universityCtrl.text = result.university;
            departmentCtrl.text = result.department;
            programCtrl.text = result.program;
            semesterCtrl.text = result.semester;
            batchCtrl.text = result.batch;
            cgpaCtrl.text = result.cgpa.toStringAsFixed(2);
            _photoUrl = result.profileImageUrl.isNotEmpty
                ? result.profileImageUrl
                : null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (x != null) {
      setState(() {
        _photo = File(x.path);
        // keep previous _photoUrl until save succeeds
      });
    }
  }

  Future<void> _save() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    setState(() => saving = true);

    try {
      String? imageUrl = _photoUrl;
      // Upload only when user picked a new local file
      if (_photo != null) {
        try {
          imageUrl = await _storageService.uploadProfileImage(
            uid: uid,
            file: _photo!,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Photo upload failed (check Storage rules). Profile text will still save. $e',
                ),
              ),
            );
          }
        }
      }

      final cgpa = double.tryParse(cgpaCtrl.text) ?? 0;
      final data = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        'studentId': studentIdCtrl.text.trim(),
        'university': universityCtrl.text.trim(),
        'department': departmentCtrl.text.trim(),
        'program': programCtrl.text.trim(),
        'semester': semesterCtrl.text.trim(),
        'batch': batchCtrl.text.trim(),
        'cgpa': cgpa,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['profileImageUrl'] = imageUrl;
      }

      await _firestoreService.updateStudent(uid, data);
      await _loadProfile();
      if (mounted) {
        setState(() {
          editing = false;
          saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password'),
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (currentCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter current password')),
                );
                return;
              }
              if (passCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New password min 6 characters')),
                );
                return;
              }
              if (passCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }
              try {
                await _authService.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: passCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Password changed! Use NEW password next login.'),
                    ),
                  );
                }
              } catch (e) {
                final msg = e.toString().toLowerCase();
                String show = 'Password change failed.';
                if (msg.contains('wrong-password') ||
                    msg.contains('invalid-credential') ||
                    msg.contains('invalid-login')) {
                  show = 'Current password is wrong.';
                } else if (msg.contains('weak-password')) {
                  show = 'New password too weak.';
                } else if (msg.contains('requires-recent-login')) {
                  show = 'Logout, login again, then change password.';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(show)));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    studentIdCtrl.dispose();
    universityCtrl.dispose();
    departmentCtrl.dispose();
    programCtrl.dispose();
    semesterCtrl.dispose();
    batchCtrl.dispose();
    cgpaCtrl.dispose();
    super.dispose();
  }

  ImageProvider? get _avatarImage {
    if (_photo != null) return FileImage(_photo!);
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final img = _avatarImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(editing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => editing = !editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: editing ? _pickPhoto : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6C63FF),
                    backgroundImage: img,
                    child: img == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 50)
                        : null,
                  ),
                  if (editing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFA6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            if (editing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tap photo → pick image → Save Changes to keep it',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 15),
            if (!editing) ...[
              Text(student?.name ?? 'Student',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(student?.email ?? '',
                  style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            if (editing) ...[
              _field(nameCtrl, 'Name'),
              _field(studentIdCtrl, 'Student ID'),
              _field(universityCtrl, 'University'),
              _field(departmentCtrl, 'Department'),
              _field(programCtrl, 'Program'),
              _field(semesterCtrl, 'Semester'),
              _field(batchCtrl, 'Batch'),
              _field(cgpaCtrl, 'CGPA', keyboard: TextInputType.number),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ] else ...[
              _info('Student ID', student?.studentId ?? ''),
              _info('University', student?.university ?? ''),
              _info('Department', student?.department ?? ''),
              _info('Program', student?.program ?? ''),
              _info('Semester', student?.semester ?? ''),
              _info('Batch', student?.batch ?? ''),
              _info('CGPA', student?.cgpa.toStringAsFixed(2) ?? '0.00'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

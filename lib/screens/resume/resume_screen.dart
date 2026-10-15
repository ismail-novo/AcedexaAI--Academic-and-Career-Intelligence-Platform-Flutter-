import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/student_model.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _auth = AuthService();
  final _fs = FirestoreService();
  StudentModel? student;
  bool loading = true;

  final _skillsCtrl = TextEditingController();
  final _projectsCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController(
      text: 'Motivated CS student seeking opportunities to apply technical skills.');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      student = await _fs.getStudent(uid);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _generatePdf({required bool includeExtra}) async {
    final name = student?.name ?? 'Student';
    final email = student?.email ?? '';
    final uni = student?.university ?? '';
    final dept = student?.department ?? '';
    final program = student?.program ?? '';
    final cgpa = student?.cgpa.toStringAsFixed(2) ?? '0.00';
    final batch = student?.batch ?? '';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(name,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('$email  |  $uni  |  $dept'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),
              _section('Career Objective', _objectiveCtrl.text),
              _section(
                'Education',
                '$program — $uni\nDepartment: $dept | Batch: $batch | CGPA: $cgpa',
              ),
              if (includeExtra && _skillsCtrl.text.trim().isNotEmpty)
                _section('Skills', _skillsCtrl.text),
              if (includeExtra && _projectsCtrl.text.trim().isNotEmpty)
                _section('Projects', _projectsCtrl.text),
              if (includeExtra && _experienceCtrl.text.trim().isNotEmpty)
                _section('Experience', _experienceCtrl.text),
              if (!includeExtra)
                _section(
                  'Profile Highlights',
                  'Student ID: ${student?.studentId ?? "-"}\n'
                  'Semester: ${student?.semester ?? "-"}\n'
                  'Career Goal: ${student?.careerGoal.isNotEmpty == true ? student!.careerGoal : "Exploring opportunities"}',
                ),
              pw.SizedBox(height: 20),
              pw.Text('Generated with Acadexa AI — ATS Friendly Format',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${name.replaceAll(' ', '_')}_Resume.pdf',
    );
  }

  pw.Widget _section(String title, String body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple)),
        pw.SizedBox(height: 4),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 14),
      ],
    );
  }

  @override
  void dispose() {
    _skillsCtrl.dispose();
    _projectsCtrl.dispose();
    _experienceCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume & ATS',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Build your professional ATS-friendly resume',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _optionCard(
              title: '1) Build from current profile info',
              subtitle:
                  'Uses name, university, department, CGPA, etc. from your Acadexa profile.',
              button: 'Generate Resume',
              onTap: () => _generatePdf(includeExtra: false),
            ),
            const SizedBox(height: 16),
            _optionCard(
              title: '2) Add other info then generate',
              subtitle: 'Add skills, projects, experience below first.',
              button: null,
              onTap: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _objectiveCtrl,
              maxLines: 2,
              decoration: _dec('Career Objective'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _skillsCtrl,
              maxLines: 2,
              decoration: _dec('Skills (comma separated)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _projectsCtrl,
              maxLines: 3,
              decoration: _dec('Projects'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _experienceCtrl,
              maxLines: 3,
              decoration: _dec('Experience / Internships'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _generatePdf(includeExtra: true),
                icon: const Icon(Icons.download),
                label: const Text('Generate & Download Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Widget _optionCard({
    required String title,
    required String subtitle,
    String? button,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (button != null && onTap != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA6),
                foregroundColor: Colors.white,
              ),
              child: Text(button),
            ),
          ],
        ],
      ),
    );
  }
}

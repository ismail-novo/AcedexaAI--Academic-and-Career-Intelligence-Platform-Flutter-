import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../services/firestore_service.dart';

class UnifiedResumeScreen extends StatefulWidget {
  const UnifiedResumeScreen({super.key});
  @override
  State<UnifiedResumeScreen> createState() => _UnifiedResumeScreenState();
}

class _UnifiedResumeScreenState extends State<UnifiedResumeScreen> {
  final _intel = IntelligenceService();
  final _prompt = TextEditingController();
  final _jd = TextEditingController();
  bool _loading = true;
  String _generated = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _intel.load(uid: AuthService().currentUser?.uid);
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final s = await FirestoreService().getStudent(uid);
      if (s != null) {
        _prompt.text = '''
Name: ${s.name}
Email: ${s.email}
Education: ${s.program}, ${s.department}, ${s.university}
Semester: ${s.semester} | CGPA: ${s.cgpa}
Student ID: ${s.studentId}
Skills: Flutter, Dart, problem solving
Projects: Acadexa AI student platform
Objective: Seeking internship/entry role aligned with my skills
''';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _buildAtsText() {
    final raw = _prompt.text.trim();
    if (raw.isEmpty) return;
    // Simple ATS-friendly restructuring
    final lines = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final buf = StringBuffer();
    buf.writeln('PROFESSIONAL SUMMARY');
    buf.writeln(
        'Motivated student building practical skills through coursework, projects, and continuous learning.');
    buf.writeln('');
    buf.writeln('PROFILE & DETAILS');
    for (final l in lines) {
      buf.writeln('• $l');
    }
    buf.writeln('');
    buf.writeln('SKILLS');
    final skills = raw.isNotEmpty ? raw.split(',').map((s) => s.trim()).toList() : <String>[];
    buf.writeln(skills.isEmpty
        ? '• Communication, Teamwork, Problem Solving'
        : skills.map((s) => '• $s').join('\n'));
    buf.writeln('');
    buf.writeln('EXPERIENCE / PROJECTS');
    buf.writeln(
        '• Academic and personal projects demonstrating applied knowledge (see profile details above).');
    buf.writeln('');
    buf.writeln('EDUCATION');
    buf.writeln('• See education lines in profile section.');
    setState(() => _generated = buf.toString());
  }

  Future<void> _downloadPdf() async {
    if (_generated.isEmpty) _buildAtsText();
    if (_generated.isEmpty) return;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text('RESUME',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text(_generated, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
    // also save copy
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(
          '${dir.path}/acadexa_resume_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await f.writeAsBytes(await doc.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${f.path}')),
        );
      }
    } catch (_) {}
  }

  Future<void> _matchJd() async {
    if (_generated.isEmpty) _buildAtsText();
    final a = _intel.analyzeResumeVsJd(
      resumeText: _generated.isEmpty ? _prompt.text : _generated,
      jobDescription: _jd.text,
    );
    await _intel.saveResumeAnalysis(a);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Match ${a.alignmentPercent.toStringAsFixed(0)}% (estimate)'),
        content: Text(
            'Matched: ${a.matched.join(', ')}\nMissing: ${a.missing.join(', ')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    _jd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter or edit resume details (prompt). Generate ATS-friendly text, download PDF, optionally match a job description.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prompt,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Resume content / prompt',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _buildAtsText,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white),
                  child: const Text('Generate ATS text'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _downloadPdf,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA6),
                      foregroundColor: Colors.white),
                  child: const Text('Download PDF'),
                ),
              ),
            ],
          ),
          if (_generated.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Text(_generated, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const Divider(height: 32),
          const Text('Job description match (optional)'),
          TextField(
            controller: _jd,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Paste JD here',
            ),
          ),
          TextButton(onPressed: _matchJd, child: const Text('Compare skills')),
        ],
      ),
    );
  }
}

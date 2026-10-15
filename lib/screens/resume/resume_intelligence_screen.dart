import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class ResumeIntelligenceScreen extends StatefulWidget {
  const ResumeIntelligenceScreen({super.key});
  @override
  State<ResumeIntelligenceScreen> createState() =>
      _ResumeIntelligenceScreenState();
}

class _ResumeIntelligenceScreenState extends State<ResumeIntelligenceScreen> {
  final _intel = IntelligenceService();
  final _resume = TextEditingController();
  final _jd = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _analyze() async {
    if (_resume.text.trim().isEmpty || _jd.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste resume and job description')),
      );
      return;
    }
    final a = _intel.analyzeResumeVsJd(
      resumeText: _resume.text,
      jobDescription: _jd.text,
    );
    await _intel.saveResumeAnalysis(a);
    setState(() {});
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            'Alignment ${a.alignmentPercent.toStringAsFixed(0)}% (estimate)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Textual skill overlap estimate — not an ATS guarantee or hiring probability.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text('Matched: ${a.matched.join(', ')}'),
              const SizedBox(height: 8),
              Text('Missing vs JD: ${a.missing.join(', ')}'),
              const SizedBox(height: 8),
              Text('Resume skills found: ${a.resumeSkills.join(', ')}'),
            ],
          ),
        ),
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
    _resume.dispose();
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
        title: const Text('Resume Intelligence',
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
            'Paste resume text (or export from Resume builder). Skill extraction uses a configurable dictionary baseline.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _resume,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Resume text',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jd,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Job description',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _analyze,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            child: const Text('Compare resume ↔ JD'),
          ),
          const SizedBox(height: 20),
          const Text('Past analyses',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ..._intel.resumeAnalyses.take(8).map((a) => ListTile(
                title: Text(
                    '${a.alignmentPercent.toStringAsFixed(0)}% · ${a.matched.length} matched'),
                subtitle: Text('Missing: ${a.missing.take(5).join(', ')}'),
              )),
        ],
      ),
    );
  }
}

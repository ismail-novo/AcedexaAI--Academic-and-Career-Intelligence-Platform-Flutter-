import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../services/local_data_service.dart';

class UnifiedCareerScreen extends StatefulWidget {
  const UnifiedCareerScreen({super.key});
  @override
  State<UnifiedCareerScreen> createState() => _UnifiedCareerScreenState();
}

class _UnifiedCareerScreenState extends State<UnifiedCareerScreen> {
  final _intel = IntelligenceService();
  final _local = LocalDataService();
  bool _loading = true;
  List<Map<String, dynamic>> _paths = [];
  String _insight = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService().currentUser?.uid;
    await _intel.load(uid: uid);
    await _local.load(uid: uid);
    _compute();
    if (mounted) setState(() => _loading = false);
  }

  void _compute() {
    // Skills from quiz topics mastery + assessments + brain + resume analyses
    final skills = <String>{};
    for (final t in _intel.topicMastery.keys) {
      if ((_intel.topicMastery[t] ?? 0) >= 40) {
        skills.add(t.toLowerCase());
        if (t.toLowerCase().contains('program')) {
          skills.addAll(['python', 'git', 'sql']);
        }
      }
    }
    for (final a in _intel.resumeAnalyses) {
      skills.addAll(a.resumeSkills);
    }
    // map quiz topics to skill tags
    for (final r in _local.quizResults) {
      final t = r.topic.toLowerCase();
      if (t.contains('program') || t.contains('mixed')) {
        skills.addAll(['python', 'git', 'dart', 'flutter']);
      }
      if (t.contains('math')) skills.add('data analysis');
      if (t.contains('network')) skills.addAll(['linux', 'rest api']);
      if (t.contains('database') || t.contains('db')) skills.add('sql');
      if (t.contains('ai')) skills.addAll(['python', 'machine learning']);
    }
    if ((_intel.brainSkills['Problem Solving'] ?? 0) > 30) {
      skills.add('project management');
    }
    if ((_intel.brainSkills['Logic'] ?? 0) > 30) {
      skills.add('python');
    }
    if (skills.isEmpty) {
      skills.addAll(['communication', 'git']);
    }

    _paths = _intel.recommendCareers(skills.toList());

    // Dynamic insight from risk + quiz
    final risks = _intel.riskIndicators();
    final weak = _intel.weakSubjects();
    final avgQuiz = _local.quizResults.isEmpty
        ? 0.0
        : _local.quizResults.map((e) => e.percent).reduce((a, b) => a + b) /
            _local.quizResults.length;

    final buf = StringBuffer();
    buf.writeln(
        'Based on ${ _local.quizResults.length} quiz session(s) (avg ${avgQuiz.toStringAsFixed(0)}%), '
        '${_intel.assessments.length} assessment(s), and risk signals:');
    if (weak.isNotEmpty) {
      buf.writeln('• Academic weak areas: ${weak.take(3).join(', ')} — strengthen these before role-specific interviews.');
    }
    for (final r in risks.take(2)) {
      if (r['level'] != 'low') {
        buf.writeln('• ${r['title']}: focus learning pathway on related skills.');
      }
    }
    if (_paths.isNotEmpty) {
      final top = _paths.first;
      buf.writeln(
          '• Top alignment right now: ${top['title']} (${(top['score'] as double).toStringAsFixed(0)}%). '
          'Gaps: ${(top['missing'] as List).take(4).join(', ')}.');
    }
    buf.writeln(
        'Suggestions update when you complete quizzes, assessments, brain tests, or resume matches. Not a job guarantee.');
    _insight = buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Path',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            _compute();
            setState(() {});
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_insight, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 16),
          const Text('Recommended paths (data-driven)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_paths.isEmpty)
            const Text('Complete quizzes or assessments to unlock paths.')
          else
            ..._paths.map((c) {
              final score = c['score'] as double;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text('${c['title']} · ${score.toStringAsFixed(0)}%'),
                  subtitle: Text('${c['field']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['reason'] as String),
                          Text('Matched: ${(c['matched'] as List).join(', ')}'),
                          Text('Gaps: ${(c['missing'] as List).join(', ')}'),
                          const SizedBox(height: 6),
                          const Text('Pathway:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...(c['path'] as List).map((p) => Text('• $p')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

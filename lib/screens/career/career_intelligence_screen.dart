import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';

class CareerIntelligenceScreen extends StatefulWidget {
  const CareerIntelligenceScreen({super.key});

  @override
  State<CareerIntelligenceScreen> createState() =>
      _CareerIntelligenceScreenState();
}

class _CareerIntelligenceScreenState extends State<CareerIntelligenceScreen> {
  final _data = LocalDataService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _data.load();
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, String>> _suggestions() {
    final quiz = _data.averageQuizPercent;
    final skill = _data.averageSkillPercent;
    final sessions = _data.sessions.where((s) => s.success).length;
    final strongSubjects = _data.subjects
        .where((s) => s.overall >= 60)
        .map((s) => s.name)
        .toList();

    final list = <Map<String, String>>[];

    if (quiz >= 70 || skill >= 70) {
      list.add({
        'sector': 'Software Engineering',
        'reason':
            'High quiz/skill scores (${quiz.toStringAsFixed(0)}% quiz). Strong problem-solving fit.',
      });
    }
    if (strongSubjects.any((s) =>
        s.toLowerCase().contains('data') ||
        s.toLowerCase().contains('ml') ||
        s.toLowerCase().contains('machine'))) {
      list.add({
        'sector': 'Data Science / AI',
        'reason': 'Strong in data/ML related subjects from Knowledge Map.',
      });
    }
    if (sessions >= 3) {
      list.add({
        'sector': 'Research / Academia path',
        'reason':
            'Consistent focus sessions ($sessions successful). Good discipline for deep work.',
      });
    }
    if (strongSubjects.any((s) =>
        s.toLowerCase().contains('network') ||
        s.toLowerCase().contains('os') ||
        s.toLowerCase().contains('security'))) {
      list.add({
        'sector': 'Cybersecurity / DevOps',
        'reason': 'Strong systems/networking foundation detected.',
      });
    }
    if (list.isEmpty) {
      list.add({
        'sector': 'General Software Development',
        'reason':
            'Keep taking quizzes & focus sessions. Build portfolio projects.',
      });
      list.add({
        'sector': 'UI/UX + Frontend',
        'reason':
            'Growing skill base — practice Flutter/web and ship small apps.',
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final suggestions = _suggestions();
    final quiz = _data.averageQuizPercent;
    final skill = _data.averageSkillPercent;
    final focusMins = _data.sessions
        .where((s) => s.success)
        .fold<int>(0, (a, b) => a + b.durationMin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Intelligence',
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
            const Text('Your Analytics Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip('Quiz ${quiz.toStringAsFixed(0)}%', Colors.purple),
                const SizedBox(width: 8),
                _chip('Skill ${skill.toStringAsFixed(0)}%', Colors.teal),
                const SizedBox(width: 8),
                _chip('${focusMins}m focus', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            if (_data.subjects.isNotEmpty)
              Text(
                'Strong subjects: ${_data.subjects.where((s) => s.overall >= 60).map((s) => s.name).join(", ").ifEmpty("None yet")}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            const SizedBox(height: 28),
            const Text('Recommended Sectors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...suggestions.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF6C63FF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_up,
                                color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s['sector']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s['reason']!,
                        style: TextStyle(
                            color: Colors.grey.shade700, height: 1.4),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Text(
              'Tip: Improve quiz scores & complete more focus sessions for better career matching.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

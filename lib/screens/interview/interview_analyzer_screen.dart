import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class InterviewAnalyzerScreen extends StatefulWidget {
  const InterviewAnalyzerScreen({super.key});
  @override
  State<InterviewAnalyzerScreen> createState() =>
      _InterviewAnalyzerScreenState();
}

class _InterviewAnalyzerScreenState extends State<InterviewAnalyzerScreen> {
  final _intel = IntelligenceService();
  final _answer = TextEditingController();
  String _category = 'behavioral';
  int _qIndex = 0;
  bool _loading = true;

  static const questions = {
    'behavioral': [
      'Tell me about a time you faced a difficult team conflict. What did you do?',
      'Describe a project you led and the result.',
      'When did you fail at something and what did you learn?',
    ],
    'technical': [
      'Explain how you would design a simple REST API for a notes app.',
      'What is the difference between an array and a linked list?',
      'How do you debug a performance issue in an application?',
    ],
    'general': [
      'Why are you interested in this field?',
      'Where do you see yourself in 5 years?',
      'What is your greatest strength as a student?',
    ],
    'role': [
      'How would you prioritize tasks when deadlines conflict?',
      'Describe a skill you are actively improving and how.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<String> get _qs => questions[_category] ?? questions['general']!;

  Future<void> _submit() async {
    if (_answer.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a fuller answer first')),
      );
      return;
    }
    final session = _intel.evaluateAnswer(
      category: _category,
      question: _qs[_qIndex % _qs.length],
      answer: _answer.text,
    );
    await _intel.saveInterview(session);
    _answer.clear();
    setState(() {});
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Overall ${session.overall.toStringAsFixed(0)}/100'),
        content: Text(
          'Relevance ${session.relevance.toStringAsFixed(0)} · '
          'Clarity ${session.clarity.toStringAsFixed(0)} · '
          'Completeness ${session.completeness.toStringAsFixed(0)} · '
          'Structure ${session.structure.toStringAsFixed(0)}\n\n'
          '${session.feedback}\n\n'
          'Scores use a transparent text rubric, not personality or voice analysis.',
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
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _qs[_qIndex % _qs.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Practice',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            items: questions.keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() {
              _category = v ?? 'general';
              _qIndex = 0;
            }),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(q,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _qIndex++),
            child: const Text('Next question'),
          ),
          TextField(
            controller: _answer,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA6),
                foregroundColor: Colors.white),
            child: const Text('Analyze answer'),
          ),
          const SizedBox(height: 20),
          const Text('History',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ..._intel.interviews.take(10).map((s) => ListTile(
                title: Text(s.question,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${s.category} · ${s.overall.toStringAsFixed(0)}/100'),
              )),
        ],
      ),
    );
  }
}

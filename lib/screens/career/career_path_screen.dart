import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class CareerPathScreen extends StatefulWidget {
  const CareerPathScreen({super.key});
  @override
  State<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends State<CareerPathScreen> {
  final _intel = IntelligenceService();
  final _skillsCtrl = TextEditingController(
      text: 'flutter, dart, firebase, git, python, communication');
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      _run();
      if (mounted) setState(() => _loading = false);
    });
  }

  void _run() {
    final skills = _skillsCtrl.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    // merge resume-extracted skills if any
    for (final a in _intel.resumeAnalyses) {
      skills.addAll(a.resumeSkills);
    }
    setState(() => _results = _intel.recommendCareers(skills.toSet().toList()));
  }

  @override
  void dispose() {
    _skillsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Path Recommender',
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
            'Explainable weighted skill match across multiple disciplines. '
            'Not a guarantee of success in any profession.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(
              labelText: 'Your skills (comma separated)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _run,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            child: const Text('Update recommendations'),
          ),
          const SizedBox(height: 16),
          ..._results.map((c) {
            final score = c['score'] as double;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                        const SizedBox(height: 8),
                        Text('Matched: ${(c['matched'] as List).join(', ')}'),
                        Text('Gaps: ${(c['missing'] as List).join(', ')}'),
                        const SizedBox(height: 8),
                        const Text('Suggested pathway:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...(c['path'] as List)
                            .map((p) => Text('• $p'))
                            .toList(),
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

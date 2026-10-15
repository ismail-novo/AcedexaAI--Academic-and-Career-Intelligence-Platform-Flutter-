import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class KnowledgeMapScreen extends StatefulWidget {
  const KnowledgeMapScreen({super.key});

  @override
  State<KnowledgeMapScreen> createState() => _KnowledgeMapScreenState();
}

class _KnowledgeMapScreenState extends State<KnowledgeMapScreen> {
  final _data = LocalDataService();
  final _ctrl = TextEditingController();
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

  Future<void> _add() async {
    if (_ctrl.text.trim().isEmpty) return;
    await _data.addSubject(_ctrl.text.trim());
    final game = GamificationService();
    await game.load();
    final msgs = await game.onSubjectAdded(count: _data.subjects.length);
    _ctrl.clear();
    setState(() {});
    if (mounted && msgs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msgs.join('  •  '))),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Map',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Add course / subject (e.g. CSE 3101)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Strong / Weak based on Academic + Quiz %',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _data.subjects.isEmpty
                ? const Center(
                    child: Text('No subjects yet.\nAdd your university courses.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _data.subjects.length,
                    itemBuilder: (context, i) {
                      final s = _data.subjects[i];
                      final overall = s.overall;
                      final isStrong = overall >= 60;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isStrong
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isStrong
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isStrong ? 'Strong' : 'Needs work',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isStrong
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    await _data.deleteSubject(s.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Academic: ${s.academicStrength.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Quiz: ${s.quizStrength.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${overall.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: overall / 100,
                              color: isStrong
                                  ? Colors.green
                                  : const Color(0xFF6C63FF),
                              backgroundColor: Colors.grey.shade200,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Set academic %: ',
                                    style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Slider(
                                    value: s.academicStrength,
                                    min: 0,
                                    max: 100,
                                    divisions: 20,
                                    activeColor: const Color(0xFF6C63FF),
                                    label:
                                        s.academicStrength.toStringAsFixed(0),
                                    onChanged: (v) async {
                                      await _data.updateSubjectStrength(s.id,
                                          academic: v);
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

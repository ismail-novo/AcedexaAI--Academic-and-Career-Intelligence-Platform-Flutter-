import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final _data = LocalDataService();
  final _ctrl = TextEditingController();
  bool _loading = true;
  List<String> _generatedQs = [];

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
    await _data.addMaterial(_ctrl.text.trim());
    _ctrl.clear();
    setState(() {});
  }

  void _generateFrom(String note) {
    // Simple keyword-based question generation from notes
    final words = note
        .split(RegExp(r'[\s,.\n]+'))
        .where((w) => w.length > 4)
        .take(8)
        .toList();
    setState(() {
      _generatedQs = [
        if (words.isNotEmpty)
          'What is the main idea of "${words.first}" in this material?',
        if (words.length > 1)
          'Explain how ${words[1]} relates to the topic.',
        if (words.length > 2)
          'Define: ${words[2]}',
        'List 3 key points from this study material.',
        'Write a short summary of the uploaded notes.',
        'Create one MCQ based on this content.',
        'What practical example can you give from this material?',
      ];
    });
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
        title: const Text('Study Materials',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste notes / PDF text summary (PDF file pick can be added later)',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Paste study material text here...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Material'),
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
          if (_generatedQs.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Generated Questions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._generatedQs.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${e.key + 1}. ${e.value}'),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _data.materialNotes.isEmpty
                ? const Center(child: Text('No materials yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _data.materialNotes.length,
                    itemBuilder: (context, i) {
                      final note = _data.materialNotes[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.length > 120
                                  ? '${note.substring(0, 120)}...'
                                  : note,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _generateFrom(note),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Generate Questions'),
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

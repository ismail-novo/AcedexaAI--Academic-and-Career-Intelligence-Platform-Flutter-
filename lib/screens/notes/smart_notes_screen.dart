import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../models/academic_models.dart';

class SmartNotesScreen extends StatefulWidget {
  const SmartNotesScreen({super.key});
  @override
  State<SmartNotesScreen> createState() => _SmartNotesScreenState();
}

class _SmartNotesScreenState extends State<SmartNotesScreen> {
  final _intel = IntelligenceService();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _subject = TextEditingController();
  final _tags = TextEditingController();
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    await _intel.upsertNote(SmartNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      content: _content.text.trim(),
      subject: _subject.text.trim(),
      tags: _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      updatedAt: DateTime.now(),
    ));
    _title.clear();
    _content.clear();
    setState(() {});
  }

  void _doSearch() {
    setState(() => _searchResults = _intel.searchNotes(_search.text));
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _subject.dispose();
    _tags.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final notes = _intel.notes.where((n) => !n.archived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Notes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search (keyword / overlap baseline)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _doSearch,
              ),
            ),
            onSubmitted: (_) => _doSearch(),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Search results',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._searchResults.map((r) {
              final n = r['note'] as SmartNote;
              return Card(
                child: ListTile(
                  title: Text(n.title),
                  subtitle: Text('${r['snippet']}\nScore: ${((r['score'] as double) * 100).toStringAsFixed(0)}% token overlap'),
                  isThreeLine: true,
                ),
              );
            }),
          ],
          const Divider(height: 32),
          const Text('New note',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          TextField(
              controller: _tags,
              decoration:
                  const InputDecoration(labelText: 'Tags (comma separated)')),
          TextField(
              controller: _content,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content')),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            child: const Text('Save note'),
          ),
          const SizedBox(height: 16),
          const Text('All notes',
              style: TextStyle(fontWeight: FontWeight.bold)),
          if (notes.isEmpty) const Text('No notes yet.'),
          ...notes.map((n) {
            final related = _intel.relatedNotes(n);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(n.title),
                subtitle: Text(
                    '${n.subject} · ${n.tags.join(', ')}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(n.content),
                  ),
                  if (related.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                          'Related: ${related.map((e) => e.title).join(', ')}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ),
                  TextButton(
                    onPressed: () async {
                      await _intel.deleteNote(n.id);
                      setState(() {});
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
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

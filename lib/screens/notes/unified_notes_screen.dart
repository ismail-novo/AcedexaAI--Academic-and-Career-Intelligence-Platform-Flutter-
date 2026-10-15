import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../models/academic_models.dart';

class UnifiedNotesScreen extends StatefulWidget {
  const UnifiedNotesScreen({super.key});
  @override
  State<UnifiedNotesScreen> createState() => _UnifiedNotesScreenState();
}

class _UnifiedNotesScreenState extends State<UnifiedNotesScreen> {
  final _intel = IntelligenceService();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _subject = TextEditingController();
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _files = []; // {name, path}
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _intel.load(uid: AuthService().currentUser?.uid);
    await _loadFiles();
    if (mounted) setState(() => _loading = false);
  }

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(root.path, 'acadexa_materials'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> _loadFiles() async {
    final d = await _dir();
    final list = await d.list().toList();
    _files = list
        .whereType<File>()
        .map((f) => {'name': p.basename(f.path), 'path': f.path})
        .toList();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc', 'docx', 'png', 'jpg'],
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.single;
    if (f.path == null) return;
    final dir = await _dir();
    final dest = p.join(dir.path, f.name);
    await File(f.path!).copy(dest);
    await _loadFiles();
    // Also create a note entry referencing the file
    await _intel.upsertNote(SmartNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: f.name,
      content: 'Attached file: ${f.name}\nStored at app materials folder.',
      subject: 'File',
      tags: ['attachment', p.extension(f.name).replaceAll('.', '')],
      updatedAt: DateTime.now(),
    ));
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${f.name}')),
      );
    }
  }

  Future<void> _saveNote() async {
    if (_title.text.trim().isEmpty) return;
    await _intel.upsertNote(SmartNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      content: _content.text.trim(),
      subject: _subject.text.trim(),
      tags: const ['note'],
      updatedAt: DateTime.now(),
    ));
    _title.clear();
    _content.clear();
    setState(() {});
  }

  void _performSearch() {
    setState(() => _searchResults = _intel.searchNotes(_search.text));
  }

  List<String> _genQs(String text) {
    return [
      'Summarize the main idea of this material.',
      'List 3 key points.',
      'What question would a quiz ask from this content?',
      'Explain one concept in your own words.',
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _subject.dispose();
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
        title: const Text('Notes & Materials',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickFile,
            tooltip: 'Add PDF / file from phone',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Add PDF or file from phone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Stored files',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._files.map((f) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(f['name'] as String),
                  subtitle: Text(f['path'] as String,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
          ],
          const Divider(height: 28),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search notes',
              suffixIcon: IconButton(
                  icon: const Icon(Icons.search), onPressed: _performSearch),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          ..._searchResults.map((r) {
            final n = r['note'] as SmartNote;
            return ListTile(
              title: Text(n.title),
              subtitle: Text('${r['snippet']}'),
            );
          }),
          const SizedBox(height: 12),
          const Text('New text note',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          TextField(
              controller: _content,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content')),
          ElevatedButton(onPressed: _saveNote, child: const Text('Save note')),
          const SizedBox(height: 16),
          const Text('All notes',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...notes.map((n) => Card(
                child: ExpansionTile(
                  title: Text(n.title),
                  subtitle: Text(n.subject),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(n.content),
                    ),
                    TextButton(
                      onPressed: () {
                        final qs = _genQs(n.content);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Practice questions'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: qs
                                  .map((q) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text('• $q'),
                                      ))
                                  .toList(),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                      child: const Text('Generate questions'),
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
              )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class RevisionPlannerScreen extends StatefulWidget {
  const RevisionPlannerScreen({super.key});
  @override
  State<RevisionPlannerScreen> createState() => _RevisionPlannerScreenState();
}

class _RevisionPlannerScreenState extends State<RevisionPlannerScreen> {
  final _intel = IntelligenceService();
  final _subject = TextEditingController();
  final _topic = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _add() async {
    if (_subject.text.trim().isEmpty || _topic.text.trim().isEmpty) return;
    await _intel.addRevisionTopic(
      subject: _subject.text.trim(),
      topic: _topic.text.trim(),
    );
    _topic.clear();
    setState(() {});
  }

  Future<void> _review(String id) async {
    int quality = 3;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recall quality (0–5)'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('0 = forgot, 5 = perfect recall'),
              Slider(
                value: quality.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: '$quality',
                onChanged: (v) => setS(() => quality = v.round()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _intel.reviewRevision(id, quality);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subject.dispose();
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final due = _intel.dueRevisions();
    final upcoming = _intel.revisions
        .where((r) => !due.any((d) => d.id == r.id))
        .toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Revision Planner',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Spaced-repetition baseline (SM-2 inspired). Intervals adjust by recall quality. Not a universal optimum.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(
                  labelText: 'Subject', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _topic,
              decoration: const InputDecoration(
                  labelText: 'Topic', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _add,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            child: const Text('Add to revision queue'),
          ),
          const SizedBox(height: 20),
          Text('Due now (${due.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (due.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Nothing due. Add topics or check upcoming.'),
            ),
          ...due.map((r) => Card(
                child: ListTile(
                  title: Text('${r.topic} · ${r.subject}'),
                  subtitle: Text(
                      'Interval ${r.intervalDays}d · EF ${r.easeFactor.toStringAsFixed(2)}'),
                  trailing: TextButton(
                    onPressed: () => _review(r.id),
                    child: const Text('Review'),
                  ),
                ),
              )),
          const SizedBox(height: 16),
          const Text('Upcoming',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...upcoming.take(20).map((r) => ListTile(
                dense: true,
                title: Text('${r.topic} (${r.subject})'),
                trailing: Text(DateFormat('dd MMM').format(r.nextReview)),
              )),
        ],
      ),
    );
  }
}

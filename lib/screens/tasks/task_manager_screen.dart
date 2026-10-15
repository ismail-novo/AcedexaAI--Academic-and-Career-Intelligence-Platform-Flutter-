import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final _data = LocalDataService();
  final _titleCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _addTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await _data.addTask(_titleCtrl.text.trim(), dateStr);
    _titleCtrl.clear();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final percent = _data.taskCompletionPercent;
    final sorted = [..._data.tasks]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Task Completion',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'New task...',
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
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No tasks yet. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final t = sorted[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: t.completed,
                            activeColor: const Color(0xFF6C63FF),
                            onChanged: (_) async {
                              final wasDone = t.completed;
                              await _data.toggleTask(t.id);
                              if (!wasDone && t.completed) {
                                final game = GamificationService();
                                await game.load();
                                final done = _data.tasks.where((x) => x.completed).length;
                                final msgs = await game.onTaskComplete(completedCount: done);
                                if (mounted && msgs.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(msgs.join('  •  '))),
                                  );
                                }
                              }
                              setState(() {});
                            },
                          ),
                          title: Text(
                            t.title,
                            style: TextStyle(
                              decoration: t.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: t.completed ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(t.date),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _data.deleteTask(t.id);
                              setState(() {});
                            },
                          ),
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

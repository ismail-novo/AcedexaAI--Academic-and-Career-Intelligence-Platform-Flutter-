import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../models/academic_models.dart';

class PerformanceAnalyzerScreen extends StatefulWidget {
  const PerformanceAnalyzerScreen({super.key});
  @override
  State<PerformanceAnalyzerScreen> createState() =>
      _PerformanceAnalyzerScreenState();
}

class _PerformanceAnalyzerScreenState extends State<PerformanceAnalyzerScreen> {
  final _intel = IntelligenceService();
  final _auth = AuthService();
  bool _loading = true;

  final _subject = TextEditingController();
  final _score = TextEditingController();
  final _max = TextEditingController(text: '100');
  final _topic = TextEditingController();
  String _type = 'quiz';
  final _types = ['quiz', 'class_test', 'assignment', 'midterm', 'final'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _intel.load(uid: _auth.currentUser?.uid);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final sub = _subject.text.trim();
    final sc = double.tryParse(_score.text);
    final mx = double.tryParse(_max.text) ?? 100;
    if (sub.isEmpty || sc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and score required')),
      );
      return;
    }
    await _intel.addAssessment(AssessmentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: sub,
      type: _type,
      score: sc,
      maxScore: mx,
      date: DateTime.now(),
      topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
    ));
    _score.clear();
    setState(() {});
  }

  @override
  void dispose() {
    _subject.dispose();
    _score.dispose();
    _max.dispose();
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final avg = _intel.subjectAverages();
    final recs = _intel.recommendations();
    final entries = avg.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analyzer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add assessment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(
                labelText: 'Subject', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _score,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Score', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topic,
            decoration: const InputDecoration(
                labelText: 'Topic (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _type,
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'quiz'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _add,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            child: const Text('Save assessment'),
          ),
          const SizedBox(height: 24),
          const Text('Subject averages',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No data yet. Add assessments above.')
          else ...[
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barGroups: entries.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value.clamp(0, 100),
                          color: e.value.value < 60
                              ? Colors.orange
                              : const Color(0xFF00BFA6),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox();
                          }
                          final name = entries[i].key;
                          return Text(
                            name.length > 6 ? '${name.substring(0, 6)}…' : name,
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text('${e.value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e.value < 60 ? Colors.orange : Colors.green,
                      )),
                )),
          ],
          const SizedBox(height: 16),
          const Text('Recommendations (from your data)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...recs.map((r) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline,
                      color: Color(0xFF6C63FF)),
                  title: Text(r, style: const TextStyle(fontSize: 13)),
                ),
              )),
          const SizedBox(height: 16),
          const Text('Recent assessments',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ..._intel.assessments.take(15).map((a) => ListTile(
                dense: true,
                title: Text('${a.subject} · ${a.type}'),
                subtitle: Text(
                    '${DateFormat('dd MMM').format(a.date)} ${a.topic ?? ''}'),
                trailing: Text(
                    '${a.percent.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }
}

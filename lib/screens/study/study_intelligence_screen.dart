import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/local_data_service.dart';
import 'focus_session_screen.dart';

class StudyIntelligenceScreen extends StatefulWidget {
  const StudyIntelligenceScreen({super.key});

  @override
  State<StudyIntelligenceScreen> createState() =>
      _StudyIntelligenceScreenState();
}

class _StudyIntelligenceScreenState extends State<StudyIntelligenceScreen> {
  final _data = LocalDataService();
  bool _loading = true;

  final _wakeCtrl = TextEditingController(text: '6:30 AM');
  final _eatCtrl = TextEditingController(text: '7:30 AM');
  final _bathCtrl = TextEditingController(text: '8:00 AM');
  final _uniCtrl = TextEditingController(text: '9:00 AM');
  final _studyCtrl = TextEditingController(text: '8:00 PM');
  final _sleepCtrl = TextEditingController(text: '11:00 PM');
  List<String> _generatedRoutine = [];

  String? _selectedSubject;
  int _duration = 25;
  final _durations = [5, 10, 15, 20, 25, 30, 35, 40, 60];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _data.load();
    if (mounted) setState(() => _loading = false);
  }

  void _generateRoutine() {
    setState(() {
      _generatedRoutine = [
        'Sat–Fri Daily Routine',
        '🌅 Wake up: ${_wakeCtrl.text}',
        '🍳 Breakfast: ${_eatCtrl.text}',
        '🚿 Bath / Ready: ${_bathCtrl.text}',
        '🏫 University: ${_uniCtrl.text}',
        '📚 Focus study: ${_studyCtrl.text}',
        '🌙 Sleep: ${_sleepCtrl.text}',
        '',
        'Tips: Keep phone away during focus blocks.',
        'Review Knowledge Map subjects daily.',
      ];
    });
  }

  Future<void> _startFocus() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a subject first')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          subject: _selectedSubject!,
          durationMin: _duration,
        ),
      ),
    );
    await _data.load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wakeCtrl.dispose();
    _eatCtrl.dispose();
    _bathCtrl.dispose();
    _uniCtrl.dispose();
    _studyCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Intelligence',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Daily Routine Generator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _routineField('Wake up', _wakeCtrl),
            _routineField('Breakfast', _eatCtrl),
            _routineField('Bath / Ready', _bathCtrl),
            _routineField('Go to University', _uniCtrl),
            _routineField('Study time', _studyCtrl),
            _routineField('Sleep', _sleepCtrl),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Generate My Routine (Sat–Fri)'),
              ),
            ),
            if (_generatedRoutine.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _generatedRoutine
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(l),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('2. Focus Session (Real Face Detection)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Uses front camera + ML Kit face detection.\nLeave frame 3 times → session fails.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_data.subjects.isEmpty)
              const Text('Add subjects in Knowledge Map first.',
                  style: TextStyle(color: Colors.orange))
            else
              Wrap(
                spacing: 8,
                children: _data.subjects
                    .map((s) => ChoiceChip(
                          label: Text(s.name),
                          selected: _selectedSubject == s.name,
                          onSelected: (_) =>
                              setState(() => _selectedSubject = s.name),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            const Text('Duration (minutes)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations
                  .map((d) => ChoiceChip(
                        label: Text('$d'),
                        selected: _duration == d,
                        onSelected: (_) => setState(() => _duration = d),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startFocus,
                icon: const Icon(Icons.videocam),
                label: const Text('Open Focus Camera Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('3. Session History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_data.sessions.isEmpty)
              const Text('No sessions yet.')
            else ...[
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: 60,
                    barGroups: _data.sessions
                        .take(7)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.durationMin.toDouble(),
                            color: e.value.success
                                ? const Color(0xFF00BFA6)
                                : Colors.redAccent,
                            width: 16,
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
                            if (i >= _data.sessions.length) {
                              return const SizedBox();
                            }
                            return Text(
                              DateFormat('dd/MM')
                                  .format(_data.sessions[i].date),
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28),
                      ),
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
              ..._data.sessions.take(10).map((s) {
                final high = s.concentration.where((c) => c == 2).length;
                final mid = s.concentration.where((c) => c == 1).length;
                final low = s.concentration.where((c) => c == 0).length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${s.subject} • ${s.durationMin} min',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(
                            s.success ? Icons.check_circle : Icons.cancel,
                            color: s.success ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                      Text(
                        '${DateFormat('dd MMM, hh:mm a').format(s.date)}  |  High:$high Mid:$mid Low:$low',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routineField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

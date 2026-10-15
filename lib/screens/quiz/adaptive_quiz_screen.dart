import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class _Q {
  final String topic;
  final int difficulty;
  final String question;
  final List<String> options;
  final int correct;

  const _Q(this.topic, this.difficulty, this.question, this.options, this.correct);
}

const _bank = [
  _Q('Programming', 1, 'What does IDE stand for?',
      ['Integrated Development Environment', 'Internet Data Engine', 'Internal Disk Error', 'Indexed Data Entry'], 0),
  _Q('Programming', 2, 'Which structure is LIFO?',
      ['Queue', 'Stack', 'Array', 'Tree'], 1),
  _Q('Programming', 3, 'Time complexity of binary search on sorted array?',
      ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'], 1),
  _Q('Programming', 4, 'What does SOLID\'s S stand for?',
      ['Single Responsibility', 'Simple Runtime', 'Safe Object', 'Static Link'], 0),
  _Q('Programming', 5, 'CAP theorem: you cannot simultaneously guarantee all of Consistency, Availability, and ___?',
      ['Performance', 'Partition tolerance', 'Persistence', 'Parallelism'], 1),
  _Q('Math', 1, 'Derivative of x²?',
      ['x', '2x', 'x²', '2'], 1),
  _Q('Math', 2, 'Solve: 2x + 4 = 10',
      ['x=2', 'x=3', 'x=4', 'x=5'], 1),
  _Q('Math', 3, 'Integral of 1/x dx?',
      ['x²', 'ln|x| + C', '1/x²', 'e^x'], 1),
  _Q('Networks', 2, 'HTTP status 404 means?',
      ['OK', 'Not Found', 'Server Error', 'Redirect'], 1),
  _Q('Networks', 3, 'Which layer does IP belong to in TCP/IP?',
      ['Application', 'Transport', 'Internet', 'Link'], 2),
  _Q('DB', 2, 'SQL command to retrieve data?',
      ['INSERT', 'SELECT', 'UPDATE', 'DELETE'], 1),
  _Q('DB', 4, 'ACID: Isolation prevents?',
      ['Disk failure', 'Concurrent transaction interference', 'Network lag', 'Schema changes'], 1),
];

class AdaptiveQuizScreen extends StatefulWidget {
  const AdaptiveQuizScreen({super.key});
  @override
  State<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends State<AdaptiveQuizScreen> {
  final _intel = IntelligenceService();
  final _local = LocalDataService();
  final _game = GamificationService();
  bool _loading = true;
  bool _started = false;
  bool _finished = false;
  int _index = 0;
  int _score = 0;
  int? _selected;
  late List<_Q> _questions;
  int _diff = 2;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final uid = AuthService().currentUser?.uid;
    await _intel.load(uid: uid);
    await _local.load(uid: uid);
    _diff = _intel.adaptiveDifficulty;
    if (mounted) setState(() => _loading = false);
  }

  void _start() {
    // Prefer questions near current difficulty; fill from neighbors
    final preferred = _bank.where((q) => (q.difficulty - _diff).abs() <= 1).toList();
    final pool = preferred.isNotEmpty ? preferred : _bank;
    pool.shuffle();
    _questions = pool.take(5).toList();
    if (_questions.length < 5) {
      final extra = [..._bank]..shuffle();
      for (final q in extra) {
        if (_questions.length >= 5) break;
        if (!_questions.contains(q)) _questions.add(q);
      }
    }
    setState(() {
      _started = true;
      _finished = false;
      _index = 0;
      _score = 0;
      _selected = null;
    });
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    final q = _questions[_index];
    final ok = _selected == q.correct;
    if (ok) _score++;
    await _intel.recordQuizOutcome(success: ok, topic: q.topic);
    _diff = _intel.adaptiveDifficulty;

    if (_index >= _questions.length - 1) {
      final pct = _score / _questions.length * 100;
      await _local.load();
      await _local.addQuizResult(QuizResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: 'Adaptive',
        total: _questions.length,
        correct: _score,
        date: DateTime.now(),
        type: 'adaptive',
      ));
      await _game.load();
      await _game.onQuizComplete(
        totalQuizzes: _local.quizResults.length,
        percent: pct,
      );
      setState(() => _finished = true);
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Quiz',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_started
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current difficulty level: $_diff / 5\n'
                    'Starts from your recent performance. Harder after success, easier after mistakes. Transparent thresholds — not a hidden model.',
                  ),
                  const SizedBox(height: 16),
                  if (_intel.topicMastery.isNotEmpty) ...[
                    const Text('Topic mastery estimates',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._intel.topicMastery.entries.map((e) => ListTile(
                          dense: true,
                          title: Text(e.key),
                          trailing: Text('${e.value.toStringAsFixed(0)}%'),
                        )),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white),
                      child: const Text('Start adaptive session'),
                    ),
                  ),
                ],
              )
            : _finished
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Score $_score / ${_questions.length}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('New difficulty: $_diff / 5'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _started = false);
                            _prepare();
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Q ${_index + 1}/${_questions.length} · Diff ${_questions[_index].difficulty} · Topic ${_questions[_index].topic}'),
                      const SizedBox(height: 12),
                      Text(_questions[_index].question,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      ...List.generate(_questions[_index].options.length, (i) {
                        return RadioListTile<int>(
                          value: i,
                          groupValue: _selected,
                          onChanged: (v) => setState(() => _selected = v),
                          title: Text(_questions[_index].options[i]),
                        );
                      }),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selected == null ? null : _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BFA6),
                              foregroundColor: Colors.white),
                          child: Text(_index >= _questions.length - 1
                              ? 'Finish'
                              : 'Submit & next'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

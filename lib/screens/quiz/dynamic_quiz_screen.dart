import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class DynamicQuizScreen extends StatefulWidget {
  const DynamicQuizScreen({super.key});

  @override
  State<DynamicQuizScreen> createState() => _DynamicQuizScreenState();
}

class _DynamicQuizScreenState extends State<DynamicQuizScreen> {
  final _data = LocalDataService();
  String? _topic;
  int _count = 10;
  String _type = 'MCQ';
  bool _started = false;
  bool _finished = false;
  int _current = 0;
  int _correct = 0;
  int? _selected;
  late List<_Q> _questions;

  final _topics = [
    'Data Structures',
    'Algorithms',
    'Database',
    'Operating Systems',
    'Computer Networks',
    'OOP',
    'Flutter',
    'Python',
    'Java',
    'Machine Learning',
  ];

  final _counts = [5, 10, 15, 20, 25];
  final _types = ['MCQ', 'Numerical', 'Theoretical', 'Mixed'];

  List<_Q> _generateQuestions() {
    final bank = <_Q>[
      _Q('What is the time complexity of binary search?',
          ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'], 1),
      _Q('Which data structure uses LIFO?',
          ['Queue', 'Stack', 'Tree', 'Graph'], 1),
      _Q('SQL stands for?',
          ['Structured Query Language', 'Simple Query List', 'System Query Language', 'None'], 0),
      _Q('Which is not an OOP pillar?',
          ['Encapsulation', 'Polymorphism', 'Compilation', 'Inheritance'], 2),
      _Q('Flutter uses which language?',
          ['Java', 'Kotlin', 'Dart', 'Swift'], 2),
      _Q('HTTP status 404 means?',
          ['OK', 'Not Found', 'Server Error', 'Redirect'], 1),
      _Q('Primary key uniquely identifies a?',
          ['Database', 'Table row', 'Column', 'Index'], 1),
      _Q('RAM is a type of?',
          ['Permanent storage', 'Volatile memory', 'CPU', 'GPU'], 1),
      _Q('Git is used for?',
          ['Design', 'Version control', 'Compilation', 'Hosting only'], 1),
      _Q('Recursion needs a?',
          ['Loop', 'Base case', 'Array', 'Pointer'], 1),
      _Q('TCP is?',
          ['Connectionless', 'Connection-oriented', 'Broadcast', 'UDP based'], 1),
      _Q('Big O of bubble sort worst case?',
          ['O(n)', 'O(n log n)', 'O(n²)', 'O(1)'], 2),
      _Q('Null in database means?',
          ['Zero', 'Empty string', 'Unknown/missing', 'False'], 2),
      _Q('Widget in Flutter is?',
          ['Class only', 'Immutable UI description', 'Mutable state', 'API'], 1),
      _Q('DFS uses?',
          ['Queue', 'Stack', 'Heap', 'Hash only'], 1),
      _Q('IP address version 4 has how many bits?',
          ['16', '32', '64', '128'], 1),
      _Q('Polymorphism means?',
          ['Many forms', 'One form', 'No form', 'Hiding data'], 0),
      _Q('Index improves?',
          ['Write speed only', 'Read/query speed', 'Disk size', 'Security'], 1),
      _Q('Async in Dart uses?',
          ['Thread only', 'Future/Stream', 'goto', 'Pointer'], 1),
      _Q('OS scheduler decides?',
          ['Disk format', 'Which process runs', 'RAM size', 'Font'], 1),
      _Q('Hash collision is solved by?',
          ['Sorting', 'Chaining/open addressing', 'Deleting key', 'None'], 1),
      _Q('REST API usually uses?',
          ['FTP', 'HTTP methods', 'SMTP', 'SSH only'], 1),
      _Q('Deadlock needs how many conditions?',
          ['1', '2', '3', '4'], 3),
      _Q('CNN is used in?',
          ['Networking only', 'Image/Deep learning', 'Databases', 'Compilers'], 1),
      _Q('Normalization reduces?',
          ['Queries', 'Redundancy', 'Security', 'Indexes'], 1),
    ];
    bank.shuffle();
    return bank.take(_count).toList();
  }

  void _start() {
    if (_topic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic')),
      );
      return;
    }
    _questions = _generateQuestions();
    setState(() {
      _started = true;
      _finished = false;
      _current = 0;
      _correct = 0;
      _selected = null;
    });
  }

  void _answer(int index) {
    if (_selected != null) return;
    setState(() => _selected = index);
    if (index == _questions[_current].answer) _correct++;
  }

  Future<void> _next() async {
    if (_selected == null) return;
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
      });
    } else {
      final result = QuizResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: _topic!,
        total: _questions.length,
        correct: _correct,
        date: DateTime.now(),
        type: _type,
      );
      await _data.load();
      await _data.addQuizResult(result);
      final game = GamificationService();
      await game.load();
      final msgs = await game.onQuizComplete(
        totalQuizzes: _data.quizResults.length,
        percent: result.percent,
      );
      setState(() => _finished = true);
      if (mounted && msgs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msgs.join('  •  ')), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Quiz',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _finished
          ? _buildResult()
          : _started
              ? _buildQuiz()
              : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Topic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((t) {
              final sel = _topic == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                onSelected: (_) => setState(() => _topic = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text('Number of Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _counts.map((c) {
              return ChoiceChip(
                label: Text('$c'),
                selected: _count == c,
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                onSelected: (_) => setState(() => _count = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text('Question Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _types.map((t) {
              return ChoiceChip(
                label: Text(t),
                selected: _type == t,
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Start Quiz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_current];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${_current + 1}/${_questions.length}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            color: const Color(0xFF6C63FF),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 24),
          Text(q.question,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ...List.generate(q.options.length, (i) {
            Color? bg;
            if (_selected != null) {
              if (i == q.answer) bg = Colors.green.shade100;
              else if (i == _selected) bg = Colors.red.shade100;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: bg ?? Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _answer(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(q.options[i],
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selected == null ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _current < _questions.length - 1 ? 'Next' : 'Finish',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final percent = (_correct / _questions.length) * 100;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Color(0xFF6C63FF)),
          const SizedBox(height: 12),
          Text('Score: $_correct / ${_questions.length}',
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF))),
          const SizedBox(height: 8),
          Text('Topic: $_topic  •  Type: $_type',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Result Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _questions.length.toDouble(),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: _correct.toDouble(),
                      color: Colors.green,
                      width: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: (_questions.length - _correct).toDouble(),
                      color: Colors.redAccent,
                      width: 40,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        v == 0 ? 'Correct' : 'Wrong',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
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
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _started = false;
                _finished = false;
                _topic = null;
              });
            },
            child: const Text('Take Another Quiz'),
          ),
        ],
      ),
    );
  }
}

class _Q {
  final String question;
  final List<String> options;
  final int answer;
  _Q(this.question, this.options, this.answer);
}

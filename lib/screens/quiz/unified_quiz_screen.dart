import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';

class QuizItem {
  final String id;
  final String topic;
  final int difficulty;
  final String question;
  final List<String> options;
  final int correct;
  const QuizItem(this.id, this.topic, this.difficulty, this.question,
      this.options, this.correct);
}

/// Large static bank — each item has unique id so sessions avoid repeats.
const kQuizBank = <QuizItem>[
  QuizItem('p1', 'Programming', 1, 'What does IDE stand for?',
      ['Integrated Development Environment', 'Internet Data Engine', 'Internal Disk Error', 'Indexed Data Entry'], 0),
  QuizItem('p2', 'Programming', 1, 'Which symbol ends a statement in Java/C?',
      [';', ':', '.', ','], 0),
  QuizItem('p3', 'Programming', 2, 'Which structure is LIFO?',
      ['Queue', 'Stack', 'Array', 'Tree'], 1),
  QuizItem('p4', 'Programming', 2, 'Git command to upload commits?',
      ['git pull', 'git push', 'git fetch', 'git clone'], 1),
  QuizItem('p5', 'Programming', 3, 'Binary search time complexity (sorted)?',
      ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'], 1),
  QuizItem('p6', 'Programming', 3, 'HTTP method to create a resource?',
      ['GET', 'POST', 'DELETE', 'HEAD'], 1),
  QuizItem('p7', 'Programming', 4, 'SOLID S principle?',
      ['Single Responsibility', 'Simple Runtime', 'Safe Object', 'Static Link'], 0),
  QuizItem('p8', 'Programming', 4, 'What is a race condition?',
      ['Fast CPU', 'Concurrent access bug', 'Network lag', 'Compile error'], 1),
  QuizItem('p9', 'Programming', 5, 'CAP theorem missing guarantee with C+A?',
      ['Performance', 'Partition tolerance', 'Persistence', 'Parallelism'], 1),
  QuizItem('p10', 'Programming', 2, 'Flutter primary language?',
      ['Kotlin', 'Dart', 'Swift', 'Java'], 1),
  QuizItem('p11', 'Programming', 3, 'SQL JOIN combines rows from?',
      ['One table only', 'Two or more tables', 'Indexes', 'Views only'], 1),
  QuizItem('p12', 'Programming', 1, 'HTML stands for?',
      ['HyperText Markup Language', 'High Text Machine Language', 'Home Tool Markup', 'Hyperlinks Text Mark'], 0),
  QuizItem('m1', 'Math', 1, 'Derivative of x²?',
      ['x', '2x', 'x²', '2'], 1),
  QuizItem('m2', 'Math', 1, '2 + 2 × 2 = ?',
      ['8', '6', '4', '2'], 1),
  QuizItem('m3', 'Math', 2, 'Solve 2x+4=10',
      ['x=2', 'x=3', 'x=4', 'x=5'], 1),
  QuizItem('m4', 'Math', 2, 'Area of circle radius r?',
      ['2πr', 'πr²', 'πd', 'r²'], 1),
  QuizItem('m5', 'Math', 3, '∫(1/x) dx = ?',
      ['x²', 'ln|x|+C', '1/x²', 'e^x'], 1),
  QuizItem('m6', 'Math', 3, 'sin²θ + cos²θ = ?',
      ['0', '1', '2', 'θ'], 1),
  QuizItem('m7', 'Math', 4, 'Limit of (1+1/n)^n as n→∞?',
      ['1', 'e', 'π', '0'], 1),
  QuizItem('m8', 'Math', 2, 'Median of 1,3,5,7,9?',
      ['3', '5', '7', '9'], 1),
  QuizItem('n1', 'Networks', 1, 'IP v4 address length?',
      ['32 bit', '64 bit', '128 bit', '16 bit'], 0),
  QuizItem('n2', 'Networks', 2, 'HTTP 404 means?',
      ['OK', 'Not Found', 'Server Error', 'Redirect'], 1),
  QuizItem('n3', 'Networks', 3, 'TCP is?',
      ['Connectionless', 'Connection-oriented', 'Broadcast only', 'File system'], 1),
  QuizItem('n4', 'Networks', 3, 'DNS resolves?',
      ['IP to MAC', 'Name to IP', 'Port to process', 'Packet to frame'], 1),
  QuizItem('n5', 'Networks', 4, 'OSI layer for routing?',
      ['Physical', 'Data Link', 'Network', 'Session'], 2),
  QuizItem('d1', 'Database', 1, 'Primary key is?',
      ['Optional', 'Unique identifier', 'Foreign only', 'Index type'], 1),
  QuizItem('d2', 'Database', 2, 'SQL retrieve data?',
      ['INSERT', 'SELECT', 'UPDATE', 'DROP'], 1),
  QuizItem('d3', 'Database', 3, 'Normalization reduces?',
      ['Speed', 'Redundancy', 'Security', 'Backup'], 1),
  QuizItem('d4', 'Database', 4, 'ACID Isolation prevents?',
      ['Disk failure', 'Transaction interference', 'Network lag', 'Schema change'], 1),
  QuizItem('d5', 'Database', 2, 'NoSQL example?',
      ['MySQL', 'MongoDB', 'PostgreSQL', 'Oracle only'], 1),
  QuizItem('c1', 'Career', 1, 'ATS often parses?',
      ['Images only', 'Plain text resume structure', 'Video CV', 'Handwriting'], 1),
  QuizItem('c2', 'Career', 2, 'STAR method is for?',
      ['Coding', 'Behavioral interviews', 'Networking cables', 'Taxes'], 1),
  QuizItem('c3', 'Career', 2, 'Portfolio should show?',
      ['Only grades', 'Projects and outcomes', 'Passwords', 'Private keys'], 1),
  QuizItem('g1', 'General', 1, 'Photosynthesis needs?',
      ['Darkness only', 'Light + CO₂ + water', 'Oxygen only', 'Salt'], 1),
  QuizItem('g2', 'General', 2, 'CPU stands for?',
      ['Central Processing Unit', 'Computer Personal Utility', 'Core Power Unit', 'Control Program Utility'], 0),
  QuizItem('g3', 'General', 2, 'WWW invented roughly in?',
      ['1970s', '1989–1991', '2000s', '1960s'], 1),
  QuizItem('g4', 'General', 3, 'First electronic general computer often cited?',
      ['ENIAC', 'iPhone', 'Abacus', 'Excel'], 0),
  QuizItem('ai1', 'AI/ML', 2, 'Supervised learning uses?',
      ['No labels', 'Labeled data', 'Only images', 'Random noise'], 1),
  QuizItem('ai2', 'AI/ML', 3, 'Overfitting means?',
      ['Good generalization', 'Memorizes train data poorly on new data', 'Fast training', 'No model'], 1),
  QuizItem('ai3', 'AI/ML', 3, 'NLP deals with?',
      ['Networks only', 'Natural language', 'Hardware', 'Power supply'], 1),
  QuizItem('ai4', 'AI/ML', 4, 'Gradient descent optimizes?',
      ['Loss function', 'Keyboard layout', 'Screen size', 'Battery'], 0),
  QuizItem('sec1', 'Security', 2, 'Phishing is?',
      ['Fishing sport', 'Social engineering attack', 'Firewall rule', 'Backup type'], 1),
  QuizItem('sec2', 'Security', 3, 'HTTPS uses?',
      ['No encryption', 'TLS/SSL', 'FTP only', 'SMTP only'], 1),
  QuizItem('sec3', 'Security', 3, 'Strong password should be?',
      ['Short dictionary word', 'Long unique mixed chars', 'Your name', '123456'], 1),
];

class UnifiedQuizScreen extends StatefulWidget {
  const UnifiedQuizScreen({super.key});
  @override
  State<UnifiedQuizScreen> createState() => _UnifiedQuizScreenState();
}

class _UnifiedQuizScreenState extends State<UnifiedQuizScreen> {
  final _intel = IntelligenceService();
  final _local = LocalDataService();
  final _game = GamificationService();
  bool _loading = true;
  bool _started = false;
  bool _finished = false;
  int _count = 10;
  String? _topicFilter; // null = all
  int _index = 0;
  int _score = 0;
  int? _selected;
  List<QuizItem> _session = [];
  final _topics = <String>{};

  @override
  void initState() {
    super.initState();
    for (final q in kQuizBank) {
      _topics.add(q.topic);
    }
    _prep();
  }

  Future<void> _prep() async {
    final uid = AuthService().currentUser?.uid;
    await _intel.load(uid: uid);
    await _local.load(uid: uid);
    if (mounted) setState(() => _loading = false);
  }

  List<QuizItem> _available() {
    final used = _intel.usedQuizIds.toSet();
    var pool = kQuizBank.where((q) => !used.contains(q.id)).toList();
    if (_topicFilter != null) {
      pool = pool.where((q) => q.topic == _topicFilter).toList();
    }
    // Prefer near adaptive difficulty
    final d = _intel.adaptiveDifficulty;
    pool.sort((a, b) => (a.difficulty - d).abs().compareTo((b.difficulty - d).abs()));
    return pool;
  }

  void _start() {
    var pool = _available();
    if (pool.isEmpty) {
      // Reset cycle if all used for filter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All unique questions used for this filter — recycling unused bank order')),
      );
      pool = kQuizBank
          .where((q) => _topicFilter == null || q.topic == _topicFilter)
          .toList();
    }
    pool = List.of(pool);
    // shuffle within similar difficulty bands
    pool.shuffle();
    final n = _count.clamp(1, pool.length);
    setState(() {
      _session = pool.take(n).toList();
      _started = true;
      _finished = false;
      _index = 0;
      _score = 0;
      _selected = null;
    });
  }

  Future<void> _next() async {
    if (_selected == null) return;
    final q = _session[_index];
    final ok = _selected == q.correct;
    if (ok) _score++;
    await _intel.recordQuizOutcome(success: ok, topic: q.topic);

    if (_index >= _session.length - 1) {
      await _intel.markQuizUsed(_session.map((e) => e.id).toList());
      await _local.addQuizResult(QuizResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: _topicFilter ?? 'Mixed',
        total: _session.length,
        correct: _score,
        date: DateTime.now(),
        type: 'unified',
      ));
      await _game.load();
      await _game.onQuizComplete(
        totalQuizzes: _local.quizResults.length,
        percent: _score / _session.length * 100,
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
    final avail = _available().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_started
            ? ListView(
                children: [
                  Text('Adaptive level: ${_intel.adaptiveDifficulty}/5'),
                  Text('Unused unique questions available: $avail / ${kQuizBank.length}'),
                  const SizedBox(height: 12),
                  const Text('Topic', style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _topicFilter == null,
                        onSelected: (_) => setState(() => _topicFilter = null),
                      ),
                      ..._topics.map((t) => ChoiceChip(
                            label: Text(t),
                            selected: _topicFilter == t,
                            onSelected: (_) => setState(() => _topicFilter = t),
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Number of questions'),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20].map((n) {
                      return ChoiceChip(
                        label: Text('$n'),
                        selected: _count == n,
                        onSelected: (_) => setState(() => _count = n),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Start Quiz'),
                  ),
                ],
              )
            : _finished
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Score $_score / ${_session.length}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Difficulty now: ${_intel.adaptiveDifficulty}/5'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _started = false);
                            _prep();
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Q ${_index + 1}/${_session.length} · ${_session[_index].topic} · D${_session[_index].difficulty}'),
                      const SizedBox(height: 12),
                      Text(_session[_index].question,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...List.generate(_session[_index].options.length, (i) {
                        return RadioListTile<int>(
                          value: i,
                          groupValue: _selected,
                          title: Text(_session[_index].options[i]),
                          onChanged: (v) => setState(() => _selected = v),
                        );
                      }),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _selected == null ? null : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(_index >= _session.length - 1
                            ? 'Finish'
                            : 'Next'),
                      ),
                    ],
                  ),
      ),
    );
  }
}

import 'auth_service.dart';
import 'local_data_service.dart';
import 'intelligence_service.dart';
import 'gamification_service.dart';

/// Aggregates real student data into chart-ready structures.
/// Unavailable skills are omitted (not shown as 0% mastery).
class AnalyticsService {
  static final AnalyticsService _i = AnalyticsService._();
  factory AnalyticsService() => _i;
  AnalyticsService._();

  final _local = LocalDataService();
  final _intel = IntelligenceService();
  final _game = GamificationService();
  final _auth = AuthService();

  Future<void> load() async {
    final uid = _auth.currentUser?.uid;
    await _local.load(uid: uid);
    await _intel.load(uid: uid);
    await _game.load(uid: uid);
  }

  /// Skill board: only categories with evidence (quiz topic, brain, subjects).
  Map<String, double> skillScores() {
    final map = <String, double>{};

    // Brain games
    _intel.brainSkills.forEach((k, v) {
      if (v > 0) map[k] = v;
    });

    // Topic mastery from quizzes
    _intel.topicMastery.forEach((k, v) {
      map[k] = v;
    });

    // Subject overall from knowledge map style data
    for (final s in _local.subjects) {
      if (s.quizStrength > 0 || s.academicStrength != 50) {
        map[s.name] = s.overall;
      }
    }

    // Aggregate quiz results by topic when no mastery entry
    final byTopic = <String, List<double>>{};
    for (final q in _local.quizResults) {
      byTopic.putIfAbsent(q.topic, () => []).add(q.percent);
    }
    byTopic.forEach((topic, scores) {
      if (!map.containsKey(topic) && scores.isNotEmpty) {
        map[topic] = scores.reduce((a, b) => a + b) / scores.length;
      }
    });

    // Assessment subject averages
    final subj = _intel.subjectAverages();
    subj.forEach((k, v) {
      if (!map.containsKey(k)) map[k] = v;
    });

    return map;
  }

  double? get overallSkillAverage {
    final s = skillScores();
    if (s.isEmpty) return null;
    return s.values.reduce((a, b) => a + b) / s.length;
  }

  int get totalQuizzes => _local.quizResults.length;

  int get totalCorrect =>
      _local.quizResults.fold(0, (a, b) => a + b.correct);

  int get totalQuestions =>
      _local.quizResults.fold(0, (a, b) => a + b.total);

  double? get quizAccuracy {
    if (totalQuestions == 0) return null;
    return totalCorrect / totalQuestions * 100;
  }

  double? get averageQuizPercent {
    if (_local.quizResults.isEmpty) return null;
    return _local.averageQuizPercent;
  }

  /// Chronological quiz percents for line chart (oldest → newest)
  List<Map<String, dynamic>> quizHistory() {
    final list = [..._local.quizResults]
      ..sort((a, b) => a.date.compareTo(b.date));
    return list
        .map((q) => {
              'date': q.date,
              'percent': q.percent,
              'topic': q.topic,
              'correct': q.correct,
              'total': q.total,
            })
        .toList();
  }

  Map<String, double> quizByTopic() {
    final map = <String, List<double>>{};
    for (final q in _local.quizResults) {
      map.putIfAbsent(q.topic, () => []).add(q.percent);
    }
    return map.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  int get studySessionCount => _local.sessions.length;

  int get totalStudyMinutes =>
      _local.sessions.fold(0, (a, b) => a + b.durationMin);

  double? get studySuccessRate {
    if (_local.sessions.isEmpty) return null;
    final ok = _local.sessions.where((s) => s.success).length;
    return ok / _local.sessions.length * 100;
  }

  List<Map<String, dynamic>> studyHistory() {
    final list = [..._local.sessions]
      ..sort((a, b) => a.date.compareTo(b.date));
    return list
        .map((s) => {
              'date': s.date,
              'minutes': s.durationMin,
              'subject': s.subject,
              'success': s.success,
            })
        .toList();
  }

  /// Weekly study minutes (last 8 weeks)
  Map<String, double> weeklyStudyMinutes() {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var i = 7; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final key =
          '${weekStart.month}/${weekStart.day}';
      map[key] = 0;
    }
    for (final s in _local.sessions) {
      final weekStart = s.date.subtract(Duration(days: s.date.weekday - 1));
      final key = '${weekStart.month}/${weekStart.day}';
      if (map.containsKey(key)) {
        map[key] = map[key]! + s.durationMin;
      }
    }
    return map;
  }

  Map<String, double> brainSkills() {
    final m = <String, double>{};
    _intel.brainSkills.forEach((k, v) {
      if (v > 0) m[k] = v;
    });
    return m;
  }

  double? get brainAverage {
    final m = brainSkills();
    if (m.isEmpty) return null;
    return m.values.reduce((a, b) => a + b) / m.length;
  }

  int get assessmentCount => _intel.assessments.length;

  Map<String, double> assessmentAverages() => _intel.subjectAverages();

  List<String> insights() {
    final out = <String>[];
    final skills = skillScores();
    if (skills.isEmpty) {
      out.add(
          'No skill data yet. Take quizzes, brain tests, or log assessments to unlock analytics.');
      return out;
    }

    final sorted = skills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    out.add(
        'Highest skill: ${sorted.first.key} (${sorted.first.value.toStringAsFixed(0)}%).');
    if (sorted.length > 1) {
      out.add(
          'Needs practice: ${sorted.last.key} (${sorted.last.value.toStringAsFixed(0)}%).');
    }

    final acc = quizAccuracy;
    if (acc != null) {
      out.add(
          'Quiz accuracy: ${acc.toStringAsFixed(0)}% across $totalQuestions questions ($totalQuizzes attempts).');
      if (acc < 60) {
        out.add(
            'Suggestion: run Adaptive/Unified Quiz on weaker topics (rule-based).');
      }
    }

    final brain = brainAverage;
    if (brain != null) {
      out.add(
          'Cognitive games average: ${brain.toStringAsFixed(0)}%. Not a clinical intelligence measure.');
    }

    final study = studySuccessRate;
    if (study != null) {
      out.add(
          'Focus sessions success rate: ${study.toStringAsFixed(0)}% ($studySessionCount sessions, $totalStudyMinutes min).');
    }

    final hist = quizHistory();
    if (hist.length >= 3) {
      final recent = hist.sublist(hist.length - 3);
      final older = hist.sublist(0, (hist.length - 3).clamp(1, hist.length));
      final r = recent.map((e) => e['percent'] as double).reduce((a, b) => a + b) /
          recent.length;
      final o = older.map((e) => e['percent'] as double).reduce((a, b) => a + b) /
          older.length;
      if (r > o + 5) {
        out.add('Quiz trend: improving vs earlier attempts.');
      } else if (r < o - 5) {
        out.add('Quiz trend: recent scores lower — revise weak topics.');
      }
    }

    out.add(
        'Insights are rule-based summaries of your saved data, not ML predictions.');
    return out;
  }

  int get xp => _game.xp;
  int get level => _game.level;
  int get streak => _game.streakDays;

  double taskCompletionPercent() {
    if (_local.tasks.isEmpty) return 0;
    final done = _local.tasks.where((t) => t.completed).length;
    return done / _local.tasks.length * 100;
  }

  int get taskCount => _local.tasks.length;
}

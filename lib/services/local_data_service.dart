import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskItem {
  final String id;
  final String title;
  final String date; // yyyy-MM-dd
  bool completed;

  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'completed': completed,
      };

  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem(
        id: m['id'],
        title: m['title'],
        date: m['date'],
        completed: m['completed'] ?? false,
      );
}

class SubjectItem {
  final String id;
  final String name;
  double academicStrength; // 0-100
  double quizStrength; // 0-100

  SubjectItem({
    required this.id,
    required this.name,
    this.academicStrength = 50,
    this.quizStrength = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'academicStrength': academicStrength,
        'quizStrength': quizStrength,
      };

  factory SubjectItem.fromMap(Map<String, dynamic> m) => SubjectItem(
        id: m['id'],
        name: m['name'],
        academicStrength: (m['academicStrength'] ?? 50).toDouble(),
        quizStrength: (m['quizStrength'] ?? 0).toDouble(),
      );

  double get overall => (academicStrength + quizStrength) / 2;
}

class QuizResult {
  final String id;
  final String topic;
  final int total;
  final int correct;
  final DateTime date;
  final String type;

  QuizResult({
    required this.id,
    required this.topic,
    required this.total,
    required this.correct,
    required this.date,
    required this.type,
  });

  double get percent => total == 0 ? 0 : (correct / total) * 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'topic': topic,
        'total': total,
        'correct': correct,
        'date': date.toIso8601String(),
        'type': type,
      };

  factory QuizResult.fromMap(Map<String, dynamic> m) => QuizResult(
        id: m['id'],
        topic: m['topic'],
        total: m['total'],
        correct: m['correct'],
        date: DateTime.parse(m['date']),
        type: m['type'] ?? 'mcq',
      );
}

class SessionRecord {
  final String id;
  final String subject;
  final int durationMin;
  final bool success;
  final DateTime date;
  final List<int> concentration; // per minute 0=low 1=mid 2=high

  SessionRecord({
    required this.id,
    required this.subject,
    required this.durationMin,
    required this.success,
    required this.date,
    required this.concentration,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'durationMin': durationMin,
        'success': success,
        'date': date.toIso8601String(),
        'concentration': concentration,
      };

  factory SessionRecord.fromMap(Map<String, dynamic> m) => SessionRecord(
        id: m['id'],
        subject: m['subject'],
        durationMin: m['durationMin'],
        success: m['success'] ?? false,
        date: DateTime.parse(m['date']),
        concentration: List<int>.from(m['concentration'] ?? []),
      );
}

class LocalDataService {
  static final LocalDataService _instance = LocalDataService._();
  factory LocalDataService() => _instance;
  LocalDataService._();

  // IMPORTANT: every key below is prefixed with the signed-in user's uid so
  // that each account has its own, completely separate set of data on this
  // device. Without this prefix, creating a new account would keep showing
  // whatever the previously logged-in account had saved.
  String? _uid;

  List<TaskItem> tasks = [];
  List<SubjectItem> subjects = [];
  List<QuizResult> quizResults = [];
  List<SessionRecord> sessions = [];
  List<String> materialNotes = [];

  String _k(String base) => '${_uid ?? 'guest'}_$base';

  /// [uid] should be passed the first time this is called after a login
  /// (e.g. from DashboardScreen). Later calls can omit it and the
  /// previously-set uid will be reused.
  Future<void> load({String? uid}) async {
    if (uid != null) _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    tasks = _decodeList(prefs.getString(_k('tasks')), TaskItem.fromMap);
    subjects = _decodeList(prefs.getString(_k('subjects')), SubjectItem.fromMap);
    quizResults =
        _decodeList(prefs.getString(_k('quizResults')), QuizResult.fromMap);
    sessions = _decodeList(prefs.getString(_k('sessions')), SessionRecord.fromMap);
    materialNotes = List<String>.from(
        jsonDecode(prefs.getString(_k('materials')) ?? '[]'));
  }

  /// Resets all activity for [uid] back to a fresh, all-zero state — used by
  /// "Clear History" on the dashboard/profile. This never touches the
  /// student's profile info (name, university, etc.), which lives in
  /// Firestore, not here.
  Future<void> clearAllFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${uid}_';
    for (final base in ['tasks', 'subjects', 'quizResults', 'sessions', 'materials']) {
      await prefs.remove('$prefix$base');
    }
    if (_uid == uid) {
      tasks = [];
      subjects = [];
      quizResults = [];
      sessions = [];
      materialNotes = [];
    }
  }

  Future<void> _save(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k(key), jsonEncode(data));
  }

  List<T> _decodeList<T>(
      String? raw, T Function(Map<String, dynamic>) fromMap) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => fromMap(Map<String, dynamic>.from(e))).toList();
  }

  // ---- Tasks ----
  Future<void> addTask(String title, String date) async {
    tasks.add(TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
    ));
    await _save('tasks', tasks.map((e) => e.toMap()).toList());
  }

  Future<void> toggleTask(String id) async {
    final t = tasks.firstWhere((e) => e.id == id);
    t.completed = !t.completed;
    await _save('tasks', tasks.map((e) => e.toMap()).toList());
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((e) => e.id == id);
    await _save('tasks', tasks.map((e) => e.toMap()).toList());
  }

  double get taskCompletionPercent {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.completed).length;
    return (done / tasks.length) * 100;
  }

  // ---- Subjects ----
  Future<void> addSubject(String name) async {
    subjects.add(SubjectItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    ));
    await _save('subjects', subjects.map((e) => e.toMap()).toList());
  }

  Future<void> updateSubjectStrength(String id,
      {double? academic, double? quiz}) async {
    final s = subjects.firstWhere((e) => e.id == id);
    if (academic != null) s.academicStrength = academic;
    if (quiz != null) s.quizStrength = quiz;
    await _save('subjects', subjects.map((e) => e.toMap()).toList());
  }

  Future<void> deleteSubject(String id) async {
    subjects.removeWhere((e) => e.id == id);
    await _save('subjects', subjects.map((e) => e.toMap()).toList());
  }

  double get averageSkillPercent {
    if (subjects.isEmpty) {
      if (quizResults.isEmpty) return 0;
      final sum = quizResults.fold<double>(0, (a, b) => a + b.percent);
      return sum / quizResults.length;
    }
    final sum = subjects.fold<double>(0, (a, b) => a + b.overall);
    return sum / subjects.length;
  }

  // ---- Quiz ----
  Future<void> addQuizResult(QuizResult r) async {
    quizResults.insert(0, r);
    // update matching subject quiz strength
    for (final s in subjects) {
      if (s.name.toLowerCase() == r.topic.toLowerCase()) {
        s.quizStrength = r.percent;
      }
    }
    await _save('quizResults', quizResults.map((e) => e.toMap()).toList());
    await _save('subjects', subjects.map((e) => e.toMap()).toList());
  }

  double get averageQuizPercent {
    if (quizResults.isEmpty) return 0;
    final sum = quizResults.fold<double>(0, (a, b) => a + b.percent);
    return sum / quizResults.length;
  }

  // ---- Sessions ----
  Future<void> addSession(SessionRecord s) async {
    sessions.insert(0, s);
    await _save('sessions', sessions.map((e) => e.toMap()).toList());
  }

  // ---- Materials ----
  Future<void> addMaterial(String note) async {
    materialNotes.insert(0, note);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k('materials'), jsonEncode(materialNotes));
  }
}

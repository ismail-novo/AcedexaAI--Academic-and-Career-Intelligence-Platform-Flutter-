import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Badge.fromMap(Map<String, dynamic> m) => Badge(
        id: m['id'],
        title: m['title'],
        description: m['description'],
        emoji: m['emoji'],
        unlocked: m['unlocked'] ?? false,
        unlockedAt: m['unlockedAt'] != null
            ? DateTime.tryParse(m['unlockedAt'])
            : null,
      );

  Badge copyWith({bool? unlocked, DateTime? unlockedAt}) => Badge(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

class GamificationService {
  static final GamificationService _instance = GamificationService._();
  factory GamificationService() => _instance;
  GamificationService._();

  // Same reasoning as LocalDataService: every key is scoped to the signed-in
  // user's uid so XP/level/streak/badges never leak between accounts on the
  // same device.
  String? _uid;
  String _k(String base) => '${_uid ?? 'guest'}_$base';

  int xp = 0;
  int level = 1;
  int streakDays = 0;
  String? lastActiveDate;
  List<Badge> badges = [];

  static const List<Map<String, String>> _badgeDefs = [
    {
      'id': 'first_quiz',
      'title': 'Quiz Starter',
      'description': 'Complete your first quiz',
      'emoji': '🎯',
    },
    {
      'id': 'quiz_master',
      'title': 'Quiz Master',
      'description': 'Score 80%+ on any quiz',
      'emoji': '🏆',
    },
    {
      'id': 'five_quizzes',
      'title': 'Knowledge Hunter',
      'description': 'Complete 5 quizzes',
      'emoji': '📚',
    },
    {
      'id': 'first_session',
      'title': 'Focus Beginner',
      'description': 'Complete first focus session',
      'emoji': '⏱️',
    },
    {
      'id': 'focus_warrior',
      'title': 'Focus Warrior',
      'description': 'Complete 5 successful sessions',
      'emoji': '🧘',
    },
    {
      'id': 'task_hero',
      'title': 'Task Hero',
      'description': 'Complete 10 tasks',
      'emoji': '✅',
    },
    {
      'id': 'streak_3',
      'title': 'On Fire',
      'description': '3-day study streak',
      'emoji': '🔥',
    },
    {
      'id': 'streak_7',
      'title': 'Unstoppable',
      'description': '7-day study streak',
      'emoji': '⚡',
    },
    {
      'id': 'level_5',
      'title': 'Rising Star',
      'description': 'Reach level 5',
      'emoji': '⭐',
    },
    {
      'id': 'subject_collector',
      'title': 'Subject Collector',
      'description': 'Add 5 subjects to Knowledge Map',
      'emoji': '🗺️',
    },
  ];

  int xpForLevel(int lv) => lv * 100;

  double get levelProgress {
    final need = xpForLevel(level);
    final prev = level > 1 ? xpForLevel(level - 1) : 0;
    final into = xp - prev;
    final span = need - prev;
    if (span <= 0) return 1;
    return (into / span).clamp(0.0, 1.0);
  }

  Future<void> load({String? uid}) async {
    if (uid != null) _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    xp = prefs.getInt(_k('xp')) ?? 0;
    level = prefs.getInt(_k('level')) ?? 1;
    streakDays = prefs.getInt(_k('streakDays')) ?? 0;
    lastActiveDate = prefs.getString(_k('lastActiveDate'));

    final raw = prefs.getString(_k('badges'));
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      badges = list.map((e) => Badge.fromMap(Map<String, dynamic>.from(e))).toList();
    } else {
      badges = _badgeDefs
          .map((d) => Badge(
                id: d['id']!,
                title: d['title']!,
                description: d['description']!,
                emoji: d['emoji']!,
              ))
          .toList();
    }
    // ensure all defs exist
    for (final d in _badgeDefs) {
      if (!badges.any((b) => b.id == d['id'])) {
        badges.add(Badge(
          id: d['id']!,
          title: d['title']!,
          description: d['description']!,
          emoji: d['emoji']!,
        ));
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_k('xp'), xp);
    await prefs.setInt(_k('level'), level);
    await prefs.setInt(_k('streakDays'), streakDays);
    if (lastActiveDate != null) {
      await prefs.setString(_k('lastActiveDate'), lastActiveDate!);
    }
    await prefs.setString(
        _k('badges'), jsonEncode(badges.map((b) => b.toMap()).toList()));
  }

  /// Resets XP/level/streak/badges for [uid] back to zero — used by
  /// "Clear History". Profile info is untouched (it isn't stored here).
  Future<void> clearAllFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${uid}_';
    for (final base in ['xp', 'level', 'streakDays', 'lastActiveDate', 'badges']) {
      await prefs.remove('$prefix$base');
    }
    if (_uid == uid) {
      xp = 0;
      level = 1;
      streakDays = 0;
      lastActiveDate = null;
      badges = _badgeDefs
          .map((d) => Badge(
                id: d['id']!,
                title: d['title']!,
                description: d['description']!,
                emoji: d['emoji']!,
              ))
          .toList();
    }
  }

  Future<List<String>> addXp(int amount) async {
    xp += amount;
    final unlocked = <String>[];
    while (xp >= xpForLevel(level)) {
      level++;
      unlocked.add('Level $level reached! ⭐');
    }
    if (level >= 5) {
      final msg = await _tryUnlock('level_5');
      if (msg != null) unlocked.add(msg);
    }
    await _save();
    return unlocked;
  }

  Future<List<String>> recordActivity() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final unlocked = <String>[];
    if (lastActiveDate == today) {
      return unlocked;
    }
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    if (lastActiveDate == yesterday) {
      streakDays++;
    } else {
      streakDays = 1;
    }
    lastActiveDate = today;
    if (streakDays >= 3) {
      final m = await _tryUnlock('streak_3');
      if (m != null) unlocked.add(m);
    }
    if (streakDays >= 7) {
      final m = await _tryUnlock('streak_7');
      if (m != null) unlocked.add(m);
    }
    await _save();
    return unlocked;
  }

  Future<String?> _tryUnlock(String id) async {
    final i = badges.indexWhere((b) => b.id == id);
    if (i < 0 || badges[i].unlocked) return null;
    badges[i] = badges[i].copyWith(unlocked: true, unlockedAt: DateTime.now());
    await _save();
    return '${badges[i].emoji} Badge unlocked: ${badges[i].title}';
  }

  Future<List<String>> onQuizComplete({
    required int totalQuizzes,
    required double percent,
  }) async {
    final msgs = <String>[];
    msgs.addAll(await addXp(20 + (percent / 10).round()));
    msgs.addAll(await recordActivity());
    if (totalQuizzes >= 1) {
      final m = await _tryUnlock('first_quiz');
      if (m != null) msgs.add(m);
    }
    if (percent >= 80) {
      final m = await _tryUnlock('quiz_master');
      if (m != null) msgs.add(m);
    }
    if (totalQuizzes >= 5) {
      final m = await _tryUnlock('five_quizzes');
      if (m != null) msgs.add(m);
    }
    return msgs;
  }

  Future<List<String>> onSessionComplete({
    required int successCount,
    required bool success,
  }) async {
    final msgs = <String>[];
    if (success) {
      msgs.addAll(await addXp(30));
      msgs.addAll(await recordActivity());
      if (successCount >= 1) {
        final m = await _tryUnlock('first_session');
        if (m != null) msgs.add(m);
      }
      if (successCount >= 5) {
        final m = await _tryUnlock('focus_warrior');
        if (m != null) msgs.add(m);
      }
    }
    return msgs;
  }

  Future<List<String>> onTaskComplete({required int completedCount}) async {
    final msgs = <String>[];
    msgs.addAll(await addXp(10));
    msgs.addAll(await recordActivity());
    if (completedCount >= 10) {
      final m = await _tryUnlock('task_hero');
      if (m != null) msgs.add(m);
    }
    return msgs;
  }

  Future<List<String>> onSubjectAdded({required int count}) async {
    final msgs = <String>[];
    msgs.addAll(await addXp(5));
    if (count >= 5) {
      final m = await _tryUnlock('subject_collector');
      if (m != null) msgs.add(m);
    }
    return msgs;
  }
}

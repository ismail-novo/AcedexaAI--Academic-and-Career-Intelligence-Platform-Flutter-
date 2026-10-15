import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_models.dart';

/// Central persistence + baseline algorithms for the 8 intelligence modules.
/// All keys are uid-prefixed so multi-account isolation is preserved.
class IntelligenceService {
  static final IntelligenceService _i = IntelligenceService._();
  factory IntelligenceService() => _i;
  IntelligenceService._();

  String? _uid;
  String _k(String base) => '${_uid ?? 'guest'}_$base';

  List<AssessmentRecord> assessments = [];
  List<AcademicTarget> targets = [];
  List<RevisionItem> revisions = [];
  List<SmartNote> notes = [];
  List<InterviewSession> interviews = [];
  List<ResumeAnalysis> resumeAnalyses = [];
  int adaptiveDifficulty = 2; // 1-5
  Map<String, double> topicMastery = {}; // topic -> 0-100
  List<String> usedQuizIds = [];
  Map<String, double> brainSkills = {
    'Problem Solving': 0,
    'Logic': 0,
    'Memory': 0,
    'Strategy': 0,
  };

  Future<void> load({String? uid}) async {
    if (uid != null) _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    assessments = _list(prefs, 'assessments', AssessmentRecord.fromMap);
    targets = _list(prefs, 'targets', AcademicTarget.fromMap);
    revisions = _list(prefs, 'revisions', RevisionItem.fromMap);
    notes = _list(prefs, 'smart_notes', SmartNote.fromMap);
    interviews = _list(prefs, 'interviews', InterviewSession.fromMap);
    resumeAnalyses = _list(prefs, 'resume_analyses', ResumeAnalysis.fromMap);
    adaptiveDifficulty = prefs.getInt(_k('adaptive_diff')) ?? 2;
    final tm = prefs.getString(_k('topic_mastery'));
    topicMastery = tm == null
        ? {}
        : Map<String, double>.from(
            (jsonDecode(tm) as Map).map((k, v) => MapEntry('$k', (v as num).toDouble())));
    usedQuizIds = List<String>.from(jsonDecode(prefs.getString(_k('used_quiz_ids')) ?? '[]'));
    final bs = prefs.getString(_k('brain_skills'));
    if (bs != null) {
      brainSkills = Map<String, double>.from(
          (jsonDecode(bs) as Map).map((k, v) => MapEntry('$k', (v as num).toDouble())));
    }
  }

  List<T> _list<T>(SharedPreferences prefs, String key, T Function(Map<String, dynamic>) f) {
    final raw = prefs.getString(_k(key));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => f(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k(key), jsonEncode(data));
  }

  Future<void> clearAllFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    for (final b in [
      'assessments', 'targets', 'revisions', 'smart_notes',
      'interviews', 'resume_analyses', 'adaptive_diff', 'topic_mastery',
      'used_quiz_ids', 'brain_skills'
    ]) {
      await prefs.remove('${uid}_$b');
    }
    if (_uid == uid) {
      assessments = [];
      targets = [];
      revisions = [];
      notes = [];
      interviews = [];
      resumeAnalyses = [];
      adaptiveDifficulty = 2;
      topicMastery = {};
      usedQuizIds = [];
      brainSkills = {
        'Problem Solving': 0,
        'Logic': 0,
        'Memory': 0,
        'Strategy': 0,
      };
    }
  }

  Future<void> markQuizUsed(List<String> ids) async {
    usedQuizIds.addAll(ids);
    usedQuizIds = usedQuizIds.toSet().toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k('used_quiz_ids'), jsonEncode(usedQuizIds));
  }

  Future<void> addBrainScore(String skill, double delta) async {
    brainSkills[skill] = ((brainSkills[skill] ?? 0) + delta).clamp(0, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k('brain_skills'), jsonEncode(brainSkills));
  }


  // ---- Performance ----
  Future<void> addAssessment(AssessmentRecord a) async {
    assessments.insert(0, a);
    await _saveList('assessments', assessments.map((e) => e.toMap()).toList());
    if (a.topic != null && a.topic!.isNotEmpty) {
      final prev = topicMastery[a.topic!] ?? 50;
      topicMastery[a.topic!] = (prev * 0.6 + a.percent * 0.4).clamp(0, 100);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k('topic_mastery'), jsonEncode(topicMastery));
    }
  }

  Future<void> addTarget(AcademicTarget t) async {
    targets.insert(0, t);
    await _saveList('targets', targets.map((e) => e.toMap()).toList());
  }

  Map<String, double> subjectAverages() {
    final map = <String, List<double>>{};
    for (final a in assessments) {
      map.putIfAbsent(a.subject, () => []).add(a.percent);
    }
    return map.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  List<String> weakSubjects({double threshold = 60}) {
    final avg = subjectAverages();
    final weak = avg.entries.where((e) => e.value < threshold).map((e) => e.key).toList();
    weak.sort((a, b) => (avg[a] ?? 0).compareTo(avg[b] ?? 0));
    return weak;
  }

  List<String> recommendations() {
    final weak = weakSubjects();
    final recs = <String>[];
    for (final s in weak.take(3)) {
      final p = subjectAverages()[s]?.toStringAsFixed(0) ?? '?';
      recs.add('Focus revision on $s (avg $p%). Practice quizzes recommended.');
    }
    if (recs.isEmpty && assessments.isNotEmpty) {
      recs.add('Performance is stable. Keep spaced revision for weak topics.');
    }
    if (assessments.isEmpty) {
      recs.add('Add assessment scores to unlock personalized study recommendations.');
    }
    return recs;
  }

  // ---- Adaptive difficulty ----
  Future<void> recordQuizOutcome({required bool success, String? topic}) async {
    if (success) {
      adaptiveDifficulty = (adaptiveDifficulty + 1).clamp(1, 5);
    } else {
      adaptiveDifficulty = (adaptiveDifficulty - 1).clamp(1, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_k('adaptive_diff'), adaptiveDifficulty);
    if (topic != null && topic.isNotEmpty) {
      final prev = topicMastery[topic] ?? 50;
      topicMastery[topic] =
          (success ? prev + 8 : prev - 10).clamp(0, 100).toDouble();
      await prefs.setString(_k('topic_mastery'), jsonEncode(topicMastery));
    }
  }

  // ---- Risk (rule-based, supportive) ----
  List<Map<String, String>> riskIndicators() {
    final indicators = <Map<String, String>>[];
    final avg = subjectAverages();
    for (final e in avg.entries) {
      if (e.value < 50) {
        indicators.add({
          'level': 'high',
          'title': 'Low average in ${e.key}',
          'detail':
              'Average ${e.value.toStringAsFixed(0)}%. This is a support signal — schedule revision and practice quizzes. Not a judgment of ability.',
        });
      } else if (e.value < 60) {
        indicators.add({
          'level': 'medium',
          'title': 'Watch ${e.key}',
          'detail':
              'Average ${e.value.toStringAsFixed(0)}%. Consider extra practice before exams.',
        });
      }
    }
    // Declining trend: last 3 vs previous 3 for same subject
    final bySub = <String, List<AssessmentRecord>>{};
    for (final a in assessments) {
      bySub.putIfAbsent(a.subject, () => []).add(a);
    }
    bySub.forEach((sub, list) {
      if (list.length >= 4) {
        final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
        final recent = sorted.sublist(sorted.length - 2);
        final older = sorted.sublist(sorted.length - 4, sorted.length - 2);
        final r = recent.map((e) => e.percent).reduce((a, b) => a + b) / 2;
        final o = older.map((e) => e.percent).reduce((a, b) => a + b) / 2;
        if (r < o - 10) {
          indicators.add({
            'level': 'medium',
            'title': 'Declining trend in $sub',
            'detail':
                'Recent scores dropped vs earlier attempts. Review notes and weak topics.',
          });
        }
      }
    });
    if (indicators.isEmpty) {
      indicators.add({
        'level': 'low',
        'title': 'No urgent academic risk signals',
        'detail': assessments.isEmpty
            ? 'Add more assessment data for better monitoring.'
            : 'Keep consistent study habits. Indicators will update as you add scores.',
      });
    }
    return indicators;
  }

  // ---- Spaced repetition (SM-2 inspired baseline) ----
  Future<void> addRevisionTopic({
    required String subject,
    required String topic,
    int difficulty = 3,
  }) async {
    revisions.insert(
      0,
      RevisionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: subject,
        topic: topic,
        difficulty: difficulty,
        nextReview: DateTime.now(),
      ),
    );
    await _saveList('revisions', revisions.map((e) => e.toMap()).toList());
  }

  /// quality: 0-5 (0 again ... 5 perfect)
  Future<void> reviewRevision(String id, int quality) async {
    final i = revisions.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = revisions[i];
    int interval = r.intervalDays;
    double ef = r.easeFactor;
    int reps = r.repetitions;

    if (quality < 3) {
      reps = 0;
      interval = 1;
    } else {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 3;
      } else {
        interval = (interval * ef).round().clamp(1, 90);
      }
      reps += 1;
      ef = (ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
          .clamp(1.3, 2.8);
    }

    revisions[i] = RevisionItem(
      id: r.id,
      subject: r.subject,
      topic: r.topic,
      difficulty: r.difficulty,
      nextReview: DateTime.now().add(Duration(days: interval)),
      intervalDays: interval,
      easeFactor: ef,
      repetitions: reps,
      lastReviewed: DateTime.now(),
      lastQuality: quality,
      completed: false,
    );
    await _saveList('revisions', revisions.map((e) => e.toMap()).toList());
  }

  List<RevisionItem> dueRevisions() {
    final now = DateTime.now();
    return revisions
        .where((r) => !r.nextReview.isAfter(now.add(const Duration(hours: 12))))
        .toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }

  // ---- Notes ----
  Future<void> upsertNote(SmartNote n) async {
    final i = notes.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      notes[i] = n;
    } else {
      notes.insert(0, n);
    }
    await _saveList('smart_notes', notes.map((e) => e.toMap()).toList());
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
    await _saveList('smart_notes', notes.map((e) => e.toMap()).toList());
  }

  /// Keyword + simple token overlap "semantic" baseline (no external embedding API).
  List<Map<String, dynamic>> searchNotes(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final results = <Map<String, dynamic>>[];
    for (final n in notes.where((n) => !n.archived)) {
      final text = '${n.title} ${n.content} ${n.tags.join(' ')} ${n.subject} ${n.topic}'
          .toLowerCase();
      int hits = 0;
      for (final t in tokens) {
        if (text.contains(t)) hits++;
      }
      if (hits > 0 || text.contains(q)) {
        final score = hits / (tokens.isEmpty ? 1 : tokens.length);
        final snippetStart = text.indexOf(tokens.isNotEmpty ? tokens.first : q);
        String snippet = n.content;
        if (snippetStart >= 0 && n.content.length > 80) {
          final s = snippetStart.clamp(0, n.content.length);
          snippet = n.content.substring(s, (s + 120).clamp(0, n.content.length));
        }
        results.add({'note': n, 'score': score, 'snippet': snippet});
      }
    }
    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return results;
  }

  List<SmartNote> relatedNotes(SmartNote note) {
    final tokens = '${note.title} ${note.subject} ${note.topic} ${note.tags.join(' ')}'
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 3)
        .toSet();
    final related = <SmartNote>[];
    for (final n in notes) {
      if (n.id == note.id || n.archived) continue;
      final text = '${n.title} ${n.content}'.toLowerCase();
      final overlap = tokens.where((t) => text.contains(t)).length;
      if (overlap >= 1) related.add(n);
    }
    return related.take(5).toList();
  }

  // ---- Interview rubric ----
  InterviewSession evaluateAnswer({
    required String category,
    required String question,
    required String answer,
  }) {
    final a = answer.trim();
    final words = a.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final qTokens = question
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 3)
        .toSet();
    final aLower = a.toLowerCase();
    int overlap = qTokens.where((t) => aLower.contains(t)).length;
    double relevance = qTokens.isEmpty
        ? 50
        : (overlap / qTokens.length * 100).clamp(0, 100);

    double clarity = 40;
    if (words >= 30) clarity += 20;
    if (words >= 60) clarity += 15;
    if (a.contains('.') || a.contains('?')) clarity += 10;
    clarity = clarity.clamp(0, 100);

    double completeness = (words / 80 * 100).clamp(0, 100);
    if (category == 'behavioral') {
      // STAR hints
      final star = ['situation', 'task', 'action', 'result', 'because', 'i '];
      final hits = star.where((s) => aLower.contains(s)).length;
      completeness = ((completeness + hits * 10) / 1.2).clamp(0, 100);
    }

    double structure = 50;
    if (a.contains('\n') || a.split('.').length >= 3) structure += 20;
    if (RegExp(r'\d').hasMatch(a)) structure += 10;
    structure = structure.clamp(0, 100);

    final parts = <String>[];
    if (relevance < 55) {
      parts.add('Tie your answer more directly to the question keywords.');
    }
    if (clarity < 55) {
      parts.add('Use shorter sentences and clearer structure.');
    }
    if (completeness < 55) {
      parts.add(category == 'behavioral'
          ? 'Expand using STAR: Situation, Task, Action, Result.'
          : 'Add more concrete detail and examples.');
    }
    if (structure < 55) {
      parts.add('Organize into intro → main points → brief conclusion.');
    }
    if (parts.isEmpty) {
      parts.add('Solid answer. Refine with one quantified example if possible.');
    }

    return InterviewSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      question: question,
      answer: answer,
      relevance: relevance,
      clarity: clarity,
      completeness: completeness,
      structure: structure,
      feedback: parts.join(' '),
      date: DateTime.now(),
    );
  }

  Future<void> saveInterview(InterviewSession s) async {
    interviews.insert(0, s);
    await _saveList('interviews', interviews.map((e) => e.toMap()).toList());
  }

  // ---- Resume / JD skill match (dictionary + token baseline) ----
  static const skillDict = [
    'python', 'java', 'javascript', 'typescript', 'dart', 'flutter', 'react',
    'node', 'sql', 'firebase', 'aws', 'docker', 'git', 'linux', 'c++', 'c#',
    'machine learning', 'data analysis', 'excel', 'communication', 'leadership',
    'project management', 'ui/ux', 'figma', 'android', 'ios', 'rest api',
    'mongodb', 'postgresql', 'keras', 'tensorflow', 'pytorch', 'nlp',
    'accounting', 'marketing', 'research', 'writing', 'teaching', 'law',
    'biology', 'chemistry', 'physics', 'nursing', 'design', 'seo',
  ];

  List<String> extractSkills(String text) {
    final lower = text.toLowerCase();
    final found = <String>[];
    for (final s in skillDict) {
      if (lower.contains(s)) found.add(s);
    }
    // also capitalize-looking tokens as soft skills
    return found.toSet().toList();
  }

  ResumeAnalysis analyzeResumeVsJd({
    required String resumeText,
    required String jobDescription,
  }) {
    final rSkills = extractSkills(resumeText);
    final jSkills = extractSkills(jobDescription);
    final matched = jSkills.where((s) => rSkills.contains(s)).toList();
    final missing = jSkills.where((s) => !rSkills.contains(s)).toList();
    final pct = jSkills.isEmpty
        ? 0.0
        : (matched.length / jSkills.length * 100);

    return ResumeAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      resumeText: resumeText,
      jobDescription: jobDescription,
      resumeSkills: rSkills,
      jobSkills: jSkills,
      matched: matched,
      missing: missing,
      alignmentPercent: pct,
      date: DateTime.now(),
    );
  }

  Future<void> saveResumeAnalysis(ResumeAnalysis a) async {
    resumeAnalyses.insert(0, a);
    await _saveList(
        'resume_analyses', resumeAnalyses.map((e) => e.toMap()).toList());
  }

  // ---- Career path (explainable weighted skill match) ----
  static final careerCatalog = <Map<String, dynamic>>[
    {
      'title': 'Software Engineer',
      'field': 'Computer Science',
      'skills': ['python', 'java', 'git', 'sql', 'rest api', 'docker'],
      'path': ['DSA fundamentals', 'Build 2 portfolio apps', 'Internships', 'System design basics'],
    },
    {
      'title': 'Mobile App Developer',
      'field': 'Computer Science',
      'skills': ['flutter', 'dart', 'android', 'ios', 'firebase', 'git'],
      'path': ['Flutter UI', 'State management', 'Publish a sample app', 'Backend integration'],
    },
    {
      'title': 'Data Analyst',
      'field': 'Science / Business',
      'skills': ['python', 'excel', 'sql', 'data analysis', 'communication'],
      'path': ['SQL + Excel', 'Python pandas project', 'Dashboard portfolio', 'Domain knowledge'],
    },
    {
      'title': 'ML Engineer',
      'field': 'Computer Science',
      'skills': ['python', 'machine learning', 'tensorflow', 'pytorch', 'nlp', 'git'],
      'path': ['Math refresh', 'Classic ML projects', 'Deep learning basics', 'Deploy a model'],
    },
    {
      'title': 'UI/UX Designer',
      'field': 'Arts / Design',
      'skills': ['figma', 'ui/ux', 'design', 'communication'],
      'path': ['Design fundamentals', 'Figma case studies', 'Usability testing', 'Portfolio'],
    },
    {
      'title': 'Digital Marketer',
      'field': 'Business / Commerce',
      'skills': ['marketing', 'seo', 'communication', 'excel'],
      'path': ['SEO basics', 'Campaign analytics', 'Content strategy', 'Internship'],
    },
    {
      'title': 'Research Assistant',
      'field': 'Science / Humanities',
      'skills': ['research', 'writing', 'communication', 'data analysis'],
      'path': ['Literature review skills', 'Academic writing', 'Lab/field methods', 'Publication draft'],
    },
    {
      'title': 'Teacher / Educator',
      'field': 'Education',
      'skills': ['teaching', 'communication', 'leadership', 'writing'],
      'path': ['Subject mastery', 'Pedagogy basics', 'Practice teaching', 'Certification path'],
    },
  ];

  List<Map<String, dynamic>> recommendCareers(List<String> studentSkills) {
    final sk = studentSkills.map((s) => s.toLowerCase()).toSet();
    final out = <Map<String, dynamic>>[];
    for (final c in careerCatalog) {
      final req = List<String>.from(c['skills'] as List);
      final matched = req.where((s) => sk.contains(s)).toList();
      final missing = req.where((s) => !sk.contains(s)).toList();
      final score = req.isEmpty ? 0.0 : matched.length / req.length * 100;
      out.add({
        ...c,
        'matched': matched,
        'missing': missing,
        'score': score,
        'reason':
            'Matched ${matched.length}/${req.length} listed skills (${score.toStringAsFixed(0)}% alignment). Estimate only — not a guarantee of career fit.',
      });
    }
    out.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return out;
  }
}

class AssessmentRecord {
  final String id;
  final String subject;
  final String type; // quiz, class_test, assignment, midterm, final
  final double score;
  final double maxScore;
  final double weight; // contribution weight 0-1 or relative
  final DateTime date;
  final String? topic;

  AssessmentRecord({
    required this.id,
    required this.subject,
    required this.type,
    required this.score,
    required this.maxScore,
    this.weight = 1.0,
    required this.date,
    this.topic,
  });

  double get percent => maxScore <= 0 ? 0 : (score / maxScore) * 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'type': type,
        'score': score,
        'maxScore': maxScore,
        'weight': weight,
        'date': date.toIso8601String(),
        'topic': topic,
      };

  factory AssessmentRecord.fromMap(Map<String, dynamic> m) => AssessmentRecord(
        id: m['id'] ?? '',
        subject: m['subject'] ?? '',
        type: m['type'] ?? 'quiz',
        score: (m['score'] ?? 0).toDouble(),
        maxScore: (m['maxScore'] ?? 100).toDouble(),
        weight: (m['weight'] ?? 1).toDouble(),
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        topic: m['topic'],
      );
}

class AcademicTarget {
  final String id;
  final String subject;
  final double targetPercent;
  final DateTime? deadline;

  AcademicTarget({
    required this.id,
    required this.subject,
    required this.targetPercent,
    this.deadline,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'targetPercent': targetPercent,
        'deadline': deadline?.toIso8601String(),
      };

  factory AcademicTarget.fromMap(Map<String, dynamic> m) => AcademicTarget(
        id: m['id'] ?? '',
        subject: m['subject'] ?? '',
        targetPercent: (m['targetPercent'] ?? 70).toDouble(),
        deadline: m['deadline'] != null ? DateTime.tryParse(m['deadline']) : null,
      );
}

class RevisionItem {
  final String id;
  final String subject;
  final String topic;
  final int difficulty; // 1 easy - 5 hard
  final DateTime nextReview;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final DateTime? lastReviewed;
  final int? lastQuality; // 0-5 recall quality
  final bool completed;

  RevisionItem({
    required this.id,
    required this.subject,
    required this.topic,
    this.difficulty = 3,
    required this.nextReview,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lastReviewed,
    this.lastQuality,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'topic': topic,
        'difficulty': difficulty,
        'nextReview': nextReview.toIso8601String(),
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'repetitions': repetitions,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'lastQuality': lastQuality,
        'completed': completed,
      };

  factory RevisionItem.fromMap(Map<String, dynamic> m) => RevisionItem(
        id: m['id'] ?? '',
        subject: m['subject'] ?? '',
        topic: m['topic'] ?? '',
        difficulty: m['difficulty'] ?? 3,
        nextReview: DateTime.tryParse(m['nextReview'] ?? '') ?? DateTime.now(),
        intervalDays: m['intervalDays'] ?? 1,
        easeFactor: (m['easeFactor'] ?? 2.5).toDouble(),
        repetitions: m['repetitions'] ?? 0,
        lastReviewed: m['lastReviewed'] != null
            ? DateTime.tryParse(m['lastReviewed'])
            : null,
        lastQuality: m['lastQuality'],
        completed: m['completed'] ?? false,
      );
}

class SmartNote {
  final String id;
  final String title;
  final String content;
  final String subject;
  final String topic;
  final List<String> tags;
  final DateTime updatedAt;
  final bool archived;

  SmartNote({
    required this.id,
    required this.title,
    required this.content,
    this.subject = '',
    this.topic = '',
    this.tags = const [],
    required this.updatedAt,
    this.archived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'topic': topic,
        'tags': tags,
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived,
      };

  factory SmartNote.fromMap(Map<String, dynamic> m) => SmartNote(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        content: m['content'] ?? '',
        subject: m['subject'] ?? '',
        topic: m['topic'] ?? '',
        tags: List<String>.from(m['tags'] ?? []),
        updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
        archived: m['archived'] ?? false,
      );
}

class InterviewSession {
  final String id;
  final String category; // technical, behavioral, general, role
  final String question;
  final String answer;
  final double relevance;
  final double clarity;
  final double completeness;
  final double structure;
  final String feedback;
  final DateTime date;

  InterviewSession({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.relevance,
    required this.clarity,
    required this.completeness,
    required this.structure,
    required this.feedback,
    required this.date,
  });

  double get overall =>
      (relevance + clarity + completeness + structure) / 4;

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'question': question,
        'answer': answer,
        'relevance': relevance,
        'clarity': clarity,
        'completeness': completeness,
        'structure': structure,
        'feedback': feedback,
        'date': date.toIso8601String(),
      };

  factory InterviewSession.fromMap(Map<String, dynamic> m) => InterviewSession(
        id: m['id'] ?? '',
        category: m['category'] ?? 'general',
        question: m['question'] ?? '',
        answer: m['answer'] ?? '',
        relevance: (m['relevance'] ?? 0).toDouble(),
        clarity: (m['clarity'] ?? 0).toDouble(),
        completeness: (m['completeness'] ?? 0).toDouble(),
        structure: (m['structure'] ?? 0).toDouble(),
        feedback: m['feedback'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
      );
}

class ResumeAnalysis {
  final String id;
  final String resumeText;
  final String jobDescription;
  final List<String> resumeSkills;
  final List<String> jobSkills;
  final List<String> matched;
  final List<String> missing;
  final double alignmentPercent;
  final DateTime date;

  ResumeAnalysis({
    required this.id,
    required this.resumeText,
    required this.jobDescription,
    required this.resumeSkills,
    required this.jobSkills,
    required this.matched,
    required this.missing,
    required this.alignmentPercent,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'resumeText': resumeText,
        'jobDescription': jobDescription,
        'resumeSkills': resumeSkills,
        'jobSkills': jobSkills,
        'matched': matched,
        'missing': missing,
        'alignmentPercent': alignmentPercent,
        'date': date.toIso8601String(),
      };

  factory ResumeAnalysis.fromMap(Map<String, dynamic> m) => ResumeAnalysis(
        id: m['id'] ?? '',
        resumeText: m['resumeText'] ?? '',
        jobDescription: m['jobDescription'] ?? '',
        resumeSkills: List<String>.from(m['resumeSkills'] ?? []),
        jobSkills: List<String>.from(m['jobSkills'] ?? []),
        matched: List<String>.from(m['matched'] ?? []),
        missing: List<String>.from(m['missing'] ?? []),
        alignmentPercent: (m['alignmentPercent'] ?? 0).toDouble(),
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
      );
}

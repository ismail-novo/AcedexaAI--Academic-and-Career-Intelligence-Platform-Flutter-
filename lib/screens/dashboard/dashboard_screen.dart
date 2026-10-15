import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_data_service.dart';
import '../../services/gamification_service.dart';
import '../../models/student_model.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

import '../auth/login_screen.dart';
import '../account/manage_accounts_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_manager_screen.dart';
import '../quiz/dynamic_quiz_screen.dart';
import '../quiz/quiz_stats_screen.dart';
import '../quiz/skills_chart_screen.dart';
import '../knowledge/knowledge_map_screen.dart';
import '../study/study_intelligence_screen.dart';
import '../career/career_intelligence_screen.dart';
import '../materials/study_materials_screen.dart';
import '../resume/resume_screen.dart';
import '../gamification/achievements_screen.dart';

import '../quiz/unified_quiz_screen.dart';
import '../career/unified_career_screen.dart';
import '../knowledge/brain_test_screen.dart';
import '../resume/unified_resume_screen.dart';
import '../notes/unified_notes_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../analytics/skills_board_screen.dart';


import '../performance/performance_analyzer_screen.dart';
import '../risk/risk_monitor_screen.dart';
import '../revision/revision_planner_screen.dart';
import '../notes/smart_notes_screen.dart';
import '../interview/interview_analyzer_screen.dart';
import '../career/career_path_screen.dart';
import '../resume/resume_intelligence_screen.dart';
import '../quiz/adaptive_quiz_screen.dart';
import '../../services/intelligence_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDataService _local = LocalDataService();
  final GamificationService _game = GamificationService();
  final IntelligenceService _intel = IntelligenceService();

  StudentModel? student;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final data = await _firestoreService.getStudent(user.uid);
    // Scope local activity data (tasks, quiz results, XP, streak, etc.) to
    // THIS account's uid so a new/different account never shows another
    // account's stats.
    await _local.load(uid: user.uid);
    await _game.load(uid: user.uid);
    await _intel.load(uid: user.uid);

    if (mounted) {
      setState(() {
        student = data;
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    await _local.load();
    await _game.load();
    if (mounted) setState(() {});
  }

  Future<void> _openManageAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAccountsScreen()),
    );
    // The account being managed may have been deactivated/deleted, which
    // signs it out — send back to login just in case.
    if (_authService.currentUser == null && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Activity History?'),
        content: const Text(
          'This resets your Quiz Score, Skills, Task Completion, XP, level '
          'and streak back to 0. Your profile info (name, university, '
          'department, CGPA, etc.) will stay exactly as it is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    await _local.clearAllFor(uid);
    await _game.clearAllFor(uid);
    await _intel.clearAllFor(uid);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity history cleared. Everything shows 0 now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final studentName =
        student?.name.isNotEmpty == true ? student!.name : 'Student';
    final quizPct = _local.averageQuizPercent;
    final skillPct = _local.averageSkillPercent;
    final taskPct = _local.taskCompletionPercent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acadexa AI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _open(const ProfileScreen()),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            onPressed: _openManageAccounts,
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Manage Accounts',
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                    const SizedBox(height: 20),
                    Text(
                      'Hello, $studentName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your academic intelligence journey starts here.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI-powered student intelligence',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _confirmClearHistory,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Clear History'),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Your Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Current CGPA',
                      value: student?.cgpa.toStringAsFixed(2) ?? '0.00',
                      icon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _open(const QuizStatsScreen()),
                      child: StatCard(
                        title: 'Quiz Score',
                        value: '${quizPct.toStringAsFixed(0)}%',
                        icon: Icons.quiz_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Study Streak',
                      value: '${_local.sessions.where((s) => s.success).length} days',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _open(const SkillsBoardScreen()),
                      child: StatCard(
                        title: 'Skills',
                        value: '${skillPct.toStringAsFixed(0)}%',
                        icon: Icons.workspace_premium_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _open(const TaskManagerScreen()),
                child: StatCard(
                  title: 'Task Completion',
                  value: '${taskPct.toStringAsFixed(0)}%',
                  icon: Icons.task_alt_outlined,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _open(const AchievementsScreen()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00BFA6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech, color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level ${_game.level}  •  ${_game.xp} XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🔥 ${_game.streakDays} day streak  •  Tap for badges',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _game.levelProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text('Learn & Practice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              FeatureCard(
                title: 'Quiz',
                subtitle: 'Unique questions · adaptive difficulty',
                icon: Icons.quiz_outlined,
                onTap: () => _open(const UnifiedQuizScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Student Analytics',
                subtitle: 'Charts · trends · skills · insights',
                icon: Icons.insights_outlined,
                onTap: () => _open(const AnalyticsDashboardScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Skills Board',
                subtitle: 'Per-skill bars and percentages',
                icon: Icons.bar_chart_outlined,
                onTap: () => _open(const SkillsBoardScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Brain Test',
                subtitle: 'Chess · Sudoku · Hanoi · Tic Tac Toe',
                icon: Icons.sports_esports_outlined,
                onTap: () => _open(const BrainTestScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Performance Analyzer',
                subtitle: 'Scores, trends, weak subjects',
                icon: Icons.analytics_outlined,
                onTap: () => _open(const PerformanceAnalyzerScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Academic Risk Monitor',
                subtitle: 'Support signals from your data',
                icon: Icons.health_and_safety_outlined,
                onTap: () => _open(const RiskMonitorScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Smart Revision Planner',
                subtitle: 'Spaced repetition schedule',
                icon: Icons.event_repeat_outlined,
                onTap: () => _open(const RevisionPlannerScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Study Intelligence',
                subtitle: 'Routine + focus sessions',
                icon: Icons.timer_outlined,
                onTap: () => _open(const StudyIntelligenceScreen()),
              ),
              const SizedBox(height: 24),
              const Text('Career',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              FeatureCard(
                title: 'Career Path',
                subtitle: 'Dynamic paths from quiz & risk data',
                icon: Icons.route_outlined,
                onTap: () => _open(const UnifiedCareerScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Resume & ATS',
                subtitle: 'Prompt → ATS PDF + JD match',
                icon: Icons.description_outlined,
                onTap: () => _open(const UnifiedResumeScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Interview Practice',
                subtitle: 'Rubric feedback on answers',
                icon: Icons.record_voice_over_outlined,
                onTap: () => _open(const InterviewAnalyzerScreen()),
              ),
              const SizedBox(height: 24),
              const Text('Notes & Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              FeatureCard(
                title: 'Notes & Materials',
                subtitle: 'Text notes + PDF/files from phone',
                icon: Icons.folder_open_outlined,
                onTap: () => _open(const UnifiedNotesScreen()),
              ),
              const SizedBox(height: 12),
              FeatureCard(
                title: 'Task Manager',
                subtitle: 'Plan tasks & track completion %',
                icon: Icons.checklist_outlined,
                onTap: () => _open(const TaskManagerScreen()),
              ),
              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}

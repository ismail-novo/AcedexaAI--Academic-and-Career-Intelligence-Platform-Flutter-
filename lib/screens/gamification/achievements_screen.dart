import 'package:flutter/material.dart';
import '../../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _game = GamificationService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _game.load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unlocked = _game.badges.where((b) => b.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00BFA6)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text('Level ${_game.level}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${_game.xp} XP  •  🔥 ${_game.streakDays} day streak',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _game.levelProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_game.levelProgress * 100).toStringAsFixed(0)}% to Level ${_game.level + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Badges ($unlocked / ${_game.badges.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._game.badges.map((b) {
              final locked = !b.unlocked;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: locked ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: locked
                        ? Colors.grey.shade300
                        : const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(b.emoji,
                        style: TextStyle(
                            fontSize: 32,
                            color: locked ? Colors.grey : null)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: locked ? Colors.grey : null,
                            ),
                          ),
                          Text(
                            b.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      locked ? Icons.lock_outline : Icons.check_circle,
                      color: locked ? Colors.grey : Colors.green,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'How to earn XP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _tip('Quiz complete', '+20–30 XP'),
            _tip('Focus session success', '+30 XP'),
            _tip('Task complete', '+10 XP'),
            _tip('Add subject', '+5 XP'),
            _tip('Daily activity', 'Streak builds'),
          ],
        ),
      ),
    );
  }

  Widget _tip(String a, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(a)),
          Text(b,
              style: const TextStyle(
                  color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

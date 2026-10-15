import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';

/// Skills Board — horizontal bars so long category names never overlap.
/// Chart package for other screens remains fl_chart; this board uses a
/// responsive custom horizontal layout (best for mobile skill labels).
class SkillsBoardScreen extends StatefulWidget {
  const SkillsBoardScreen({super.key});

  @override
  State<SkillsBoardScreen> createState() => _SkillsBoardScreenState();
}

class _SkillsBoardScreenState extends State<SkillsBoardScreen> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  Map<String, double> _skills = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _analytics.load();
    _skills = _analytics.skillScores();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entries = _skills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final avg = _analytics.overallSkillAverage;
    final width = MediaQuery.sizeOf(context).width;
    // Label column width scales with screen; keeps full names readable
    final labelWidth = (width * 0.34).clamp(96.0, 140.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Skills Board',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _loading = true);
              await _load();
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No skill data yet.\n\n'
                  'Take quizzes, play Brain Test, or log assessments.\n'
                  'Unattempted skills are hidden (not shown as 0%).',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (avg != null)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.insights, color: Color(0xFF6C63FF)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Overall (skills with data)',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                Text(
                                  '${avg.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${entries.length} skills',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Skills',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Horizontal bars · 0% – 100%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                // Scale header (0 … 50 … 100) aligned with bar track
                Padding(
                  padding: EdgeInsets.only(left: labelWidth + 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0%',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500)),
                            Text('50%',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500)),
                            Text('100%',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44), // space matching % column
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Horizontal bar rows — one skill per row, full names
                ...entries.map((e) {
                  final v = e.value.clamp(0.0, 100.0);
                  final color = v >= 70
                      ? const Color(0xFF00BFA6)
                      : v >= 40
                          ? const Color(0xFF6C63FF)
                          : Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vertical-axis labels (skill names)
                        SizedBox(
                          width: labelWidth,
                          child: Text(
                            e.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Horizontal bar 0–100%
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final barMax = constraints.maxWidth;
                              final fill = (v / 100.0) * barMax;
                              return SizedBox(
                                height: 22,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Track
                                    Container(
                                      height: 14,
                                      width: barMax,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    // Fill
                                    Container(
                                      height: 14,
                                      width: fill.clamp(0, barMax),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Percentage value
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${v.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

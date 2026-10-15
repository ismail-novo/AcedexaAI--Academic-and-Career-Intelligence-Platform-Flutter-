import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/local_data_service.dart';
import '../../services/intelligence_service.dart';

/// Skills chart — horizontal bars (no overlapping bottom labels).
class SkillsChartScreen extends StatefulWidget {
  const SkillsChartScreen({super.key});
  @override
  State<SkillsChartScreen> createState() => _SkillsChartScreenState();
}

class _SkillsChartScreenState extends State<SkillsChartScreen> {
  final _data = LocalDataService();
  final _intel = IntelligenceService();
  bool _loading = true;
  final Map<String, double> _bars = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = AuthService().currentUser?.uid;
    await _data.load(uid: uid);
    await _intel.load(uid: uid);
    _bars.clear();
    _intel.brainSkills.forEach((k, v) {
      if (v > 0) _bars[k] = v;
    });
    _intel.topicMastery.forEach((k, v) {
      _bars[k] = v;
    });
    for (final s in _data.subjects) {
      try {
        _bars[s.name] = s.overall;
      } catch (_) {
        _bars[s.name] = 50;
      }
    }
    if (_bars.isEmpty && _data.quizResults.isNotEmpty) {
      _bars['Quiz average'] = _data.averageQuizPercent;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final entries = _bars.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final labelWidth =
        (MediaQuery.sizeOf(context).width * 0.34).clamp(96.0, 140.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills Board',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No skill data yet.\nPlay Brain Test or take quizzes.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Includes Brain Test + quiz topic mastery.\nHorizontal bars — labels do not overlap.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
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
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                      children: [
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
                                    Container(
                                      height: 14,
                                      width: barMax,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';
import 'skills_board_screen.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});
  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _a = AnalyticsService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _a.load();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final skills = _a.skillScores();
    final quizHist = _a.quizHistory();
    final quizTopics = _a.quizByTopic();
    final brain = _a.brainSkills();
    final weekly = _a.weeklyStudyMinutes();
    final insights = _a.insights();
    final assess = _a.assessmentAverages();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Student Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Skills Board',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SkillsBoardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _loading = true);
              await _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI cards
            const Text('Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _kpi('Quiz avg',
                    _a.averageQuizPercent == null
                        ? '—'
                        : '${_a.averageQuizPercent!.toStringAsFixed(0)}%',
                    Icons.quiz),
                _kpi('Accuracy',
                    _a.quizAccuracy == null
                        ? '—'
                        : '${_a.quizAccuracy!.toStringAsFixed(0)}%',
                    Icons.check_circle_outline),
                _kpi('Quizzes', '${_a.totalQuizzes}', Icons.list_alt),
                _kpi('Study min', '${_a.totalStudyMinutes}', Icons.timer),
                _kpi(
                    'Skills',
                    _a.overallSkillAverage == null
                        ? '—'
                        : '${_a.overallSkillAverage!.toStringAsFixed(0)}%',
                    Icons.psychology),
                _kpi('Level', '${_a.level}', Icons.star_outline),
                _kpi('Streak', '${_a.streak}d', Icons.local_fire_department),
                _kpi(
                    'Tasks',
                    _a.taskCount == 0
                        ? '—'
                        : '${_a.taskCompletionPercent().toStringAsFixed(0)}%',
                    Icons.task_alt),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...insights.map((i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline,
                        color: Color(0xFF6C63FF)),
                    title: Text(i, style: const TextStyle(fontSize: 13)),
                  ),
                )),

            const SizedBox(height: 24),
            _sectionTitle('Skill distribution'),
            if (skills.isEmpty)
              _empty('No skill data yet')
            else ...[
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: () {
                      final e = skills.entries.toList();
                      final colors = [
                        const Color(0xFF6C63FF),
                        const Color(0xFF00BFA6),
                        Colors.orange,
                        Colors.blue,
                        Colors.pink,
                        Colors.teal,
                        Colors.indigo,
                        Colors.amber,
                      ];
                      return e.asMap().entries.map((x) {
                        final pct = x.value.value;
                        return PieChartSectionData(
                          value: pct,
                          title: '${pct.toStringAsFixed(0)}%',
                          color: colors[x.key % colors.length],
                          radius: 48,
                          titleStyle: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    }(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: skills.entries.map((e) {
                  return Chip(
                    label: Text(
                        '${e.key} ${e.value.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SkillsBoardScreen()),
                  );
                },
                child: const Text('Open full Skills Board'),
              ),
            ],

            const SizedBox(height: 24),
            _sectionTitle('Quiz score trend'),
            if (quizHist.isEmpty)
              _empty('No quiz attempts yet')
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((s) {
                          final i = s.x.toInt();
                          final topic = i >= 0 && i < quizHist.length
                              ? quizHist[i]['topic']
                              : '';
                          return LineTooltipItem(
                            '$topic\n${s.y.toStringAsFixed(0)}%',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList(),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (v, m) {
                            final i = v.toInt();
                            if (i < 0 || i >= quizHist.length) {
                              return const SizedBox();
                            }
                            final d = quizHist[i]['date'] as DateTime;
                            return Text(DateFormat('dd/MM').format(d),
                                style: const TextStyle(fontSize: 9));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                          color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: quizHist.asMap().entries.map((e) {
                          return FlSpot(
                              e.key.toDouble(), e.value['percent'] as double);
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF6C63FF),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF6C63FF).withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            _sectionTitle('Quiz by topic'),
            if (quizTopics.isEmpty)
              _empty('No topic breakdown yet')
            else
              ...quizTopics.entries.map((e) => _hbar(e.key, e.value)),

            const SizedBox(height: 24),
            _sectionTitle('Brain training'),
            if (brain.isEmpty)
              _empty(
                  'No cognitive game scores yet. Play Brain Test (not a clinical IQ test).')
            else ...[
              ...brain.entries.map((e) => _hbar(e.key, e.value)),
              if (_a.brainAverage != null)
                Text(
                    'Average: ${_a.brainAverage!.toStringAsFixed(0)}% — activity score only, not intelligence diagnosis.',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
            ],

            const SizedBox(height: 24),
            _sectionTitle('Study activity (weekly minutes)'),
            if (_a.studySessionCount == 0)
              _empty('No focus sessions recorded')
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: (weekly.values.isEmpty
                            ? 60
                            : weekly.values.reduce((a, b) => a > b ? a : b))
                        .clamp(30, 999)
                        .toDouble(),
                    barGroups: weekly.entries.toList().asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.value,
                            color: const Color(0xFF00BFA6),
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final i = v.toInt();
                            final keys = weekly.keys.toList();
                            if (i < 0 || i >= keys.length) {
                              return const SizedBox();
                            }
                            return Text(keys[i],
                                style: const TextStyle(fontSize: 8));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            if (_a.studySuccessRate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sessions: ${_a.studySessionCount} · Success rate: ${_a.studySuccessRate!.toStringAsFixed(0)}%',
                ),
              ),

            const SizedBox(height: 24),
            _sectionTitle('Academic assessments'),
            if (assess.isEmpty)
              _empty('No assessments in Performance Analyzer yet')
            else
              ...assess.entries.map((e) => _hbar(e.key, e.value)),

            const SizedBox(height: 24),
            _sectionTitle('Recent quiz attempts'),
            if (quizHist.isEmpty)
              _empty('—')
            else
              ...quizHist.reversed.take(8).map((q) {
                final d = q['date'] as DateTime;
                return ListTile(
                  dense: true,
                  title: Text('${q['topic']}'),
                  subtitle: Text(DateFormat('dd MMM yyyy · HH:mm').format(d)),
                  trailing: Text(
                    '${(q['percent'] as double).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _empty(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(t, style: TextStyle(color: Colors.grey.shade600)),
      );

  Widget _kpi(String label, String value, IconData icon) {
    return SizedBox(
      width: 104,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hbar(String label, double value) {
    final v = value.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${v.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }
}

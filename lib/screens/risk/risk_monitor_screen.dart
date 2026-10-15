import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/intelligence_service.dart';

class RiskMonitorScreen extends StatefulWidget {
  const RiskMonitorScreen({super.key});
  @override
  State<RiskMonitorScreen> createState() => _RiskMonitorScreenState();
}

class _RiskMonitorScreenState extends State<RiskMonitorScreen> {
  final _intel = IntelligenceService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _intel.load(uid: AuthService().currentUser?.uid).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Color _color(String level) {
    switch (level) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final indicators = _intel.riskIndicators();
    final weak = _intel.weakSubjects();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Risk Monitor',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'These are support signals based on your saved scores — not labels of ability. '
              'Missing data reduces confidence. You can always add or correct assessments in Performance Analyzer.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          ...indicators.map((ind) {
            final c = _color(ind['level']!);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(Icons.health_and_safety, color: c),
                title: Text(ind['title']!,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(ind['detail']!),
              ),
            );
          }),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Suggested next steps',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...weak.take(3).map((s) => ListTile(
                  leading: const Icon(Icons.arrow_forward,
                      color: Color(0xFF00BFA6)),
                  title: Text('Revise $s + take a practice quiz'),
                )),
          ],
        ],
      ),
    );
  }
}

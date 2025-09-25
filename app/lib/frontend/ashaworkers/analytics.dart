import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/frontend/ashaworkers/home.dart';
import 'package:app/frontend/ashaworkers/data_collection.dart';
import 'package:app/frontend/ashaworkers/reports.dart';
import 'package:app/frontend/ashaworkers/profile.dart';

class AshaWorkerAnalyticsPage extends StatefulWidget {
  const AshaWorkerAnalyticsPage({super.key});

  @override
  State<AshaWorkerAnalyticsPage> createState() => _AshaWorkerAnalyticsPageState();
}

// --- Simple Line Chart for counts per day ---
class _LineChart extends StatelessWidget {
  final List<({DateTime day, int count})> points;
  const _LineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: const Text('No trend data in this period'),
      );
    }
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _LineChartPainter(points),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<({DateTime day, int count})> points;
  _LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), bg);

    if (points.isEmpty) return;
    final maxCount = points.map((e) => e.count).fold<int>(0, (p, c) => c > p ? c : p);
    final minDay = points.first.day;
    final maxDay = points.last.day;
    final daySpan = (maxDay.difference(minDay).inDays).clamp(1, 365);

    // Axes padding (reserve space for axis labels)
    const leftPad = 34.0; // for y-axis labels
    const bottomPad = 20.0; // for x-axis labels
    const rightPad = 12.0;
    const topPad = 10.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final line = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final area = Paint()
      ..shader = const LinearGradient(colors: [Color(0x3306B6D4), Color(0x3322C55E)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Gridlines and axes labels
    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    // Horizontal gridlines (0%, 25%, 50%, 75%, 100%)
    const gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final y = topPad + chartH * (i / gridRows);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), grid);
      final val = (maxCount * (1 - i / gridRows)).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // X-axis labels: first, middle, last
    DateTime midDay = minDay.add(Duration(days: (maxDay.difference(minDay).inDays ~/ 2)));
    List<DateTime> xLabels = [minDay, midDay, maxDay];
    for (int i = 0; i < xLabels.length; i++) {
      final d = xLabels[i];
      final xRatio = (d.difference(minDay).inDays) / daySpan;
      final x = leftPad + chartW * xRatio;
      final label = _fmtShort(d);
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 2));
    }

    final path = Path();
    final areaPath = Path();
    for (int i = 0; i < points.length; i++) {
      final d = points[i].day;
      final xRatio = (d.difference(minDay).inDays) / daySpan;
      final yRatio = maxCount == 0 ? 0.0 : (points[i].count / maxCount);
      final x = leftPad + chartW * xRatio;
      final y = topPad + chartH * (1 - yRatio);
      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, topPad + chartH);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo(leftPad + chartW, topPad + chartH);
    areaPath.close();
    canvas.drawPath(areaPath, area);
    canvas.drawPath(path, line);

    // If only one point, draw a visible dot so the user sees the trend start
    if (points.length == 1) {
      final d = points.first.day;
      final xRatio = (d.difference(minDay).inDays) / daySpan;
      final yRatio = maxCount == 0 ? 0.0 : (points.first.count / maxCount);
      final x = leftPad + chartW * xRatio;
      final y = topPad + chartH * (1 - yRatio);
      final dot = Paint()..color = const Color(0xFF06B6D4);
      canvas.drawCircle(Offset(x, y), 4.0, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

// Short date label for x-axis: DD/MM
String _fmtShort(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

List<({DateTime day, int count})> _groupByDay(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final Map<DateTime, int> map = {};
  for (final d in docs) {
    final ts = d.data()['createdAt'];
    DateTime when;
    if (ts is Timestamp) when = ts.toDate();
    else if (ts is int) when = DateTime.fromMillisecondsSinceEpoch(ts);
    else if (ts is String) when = DateTime.tryParse(ts) ?? DateTime.now();
    else when = DateTime.now();
    final key = DateTime(when.year, when.month, when.day);
    map[key] = (map[key] ?? 0) + 1;
  }
  final keys = map.keys.toList()..sort();
  return [for (final k in keys) (day: k, count: map[k]!)];
}

class _AshaWorkerAnalyticsPageState extends State<AshaWorkerAnalyticsPage> {
  int _currentIndex = 3;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.85),
              ]),
            ),
          ),
          title: Text(t('nav_analytics'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFE5E7EB),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: t('tab_today')),
              Tab(text: t('tab_this_week')),
              Tab(text: t('tab_this_month')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AnalyticsTab(period: _Period.today),
            _AnalyticsTab(period: _Period.week),
            _AnalyticsTab(period: _Period.month),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              if (i == 0) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AshaWorkerHomePage()),
                  (route) => false,
                );
              } else if (i == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaWorkerDataCollectionPage()),
                );
              } else if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaWorkerReportsPage()),
                );
              } else if (i == 4) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaWorkerProfilePage()),
                );
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: const Color(0xFF9CA3AF),
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: t('nav_home_title')),
              BottomNavigationBarItem(icon: const Icon(Icons.fact_check_outlined), label: t('nav_data_collection')),
              BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: t('nav_reports')),
              BottomNavigationBarItem(icon: const Icon(Icons.insert_chart_outlined), label: t('nav_analytics')),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), label: t('nav_profile')),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Period { today, week, month }

class _AnalyticsTab extends StatelessWidget {
  final _Period period;
  const _AnalyticsTab({required this.period});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return FutureBuilder<String?>(
      future: _getUid(),
      builder: (context, snap) {
        final uid = snap.data;
        if (uid == null || uid.isEmpty) {
          return _empty(t('no_data'));
        }
        final query = FirebaseFirestore.instance
            .collection('appdata')
            .doc('main')
            .collection('ashwadata')
            .doc(uid)
            .collection('household_surveys')
            .orderBy('createdAt', descending: true)
            .limit(200);
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(includeMetadataChanges: true),
          builder: (context, ss) {
            if (!ss.hasData) return const Center(child: CircularProgressIndicator());
            final docs = ss.data!.docs;
            final now = DateTime.now();
            final range = _rangeFor(period, now);
            final filtered = docs.where((d) {
              final ts = d.data()['createdAt'];
              DateTime when;
              if (ts is Timestamp) when = ts.toDate();
              else if (ts is int) when = DateTime.fromMillisecondsSinceEpoch(ts);
              else if (ts is String) when = DateTime.tryParse(ts) ?? now;
              else when = now;
              return !when.isBefore(range.start) && when.isBefore(range.end);
            }).toList();

            // Aggregate disease counts
            final Map<String, int> diseaseCount = {};
            int households = filtered.length;
            int affected = 0;
            for (final d in filtered) {
              final members = (d.data()['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              for (final m in members) {
                if (m['affected'] == true) {
                  affected++;
                  final dis = (m['disease'] as String?) ?? 'Unknown';
                  diseaseCount[dis] = (diseaseCount[dis] ?? 0) + 1;
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KpiRow(households: households, affected: affected),
                  const SizedBox(height: 16),
                  Text(t('trend_households'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _LineChart(points: _groupByDay(filtered)),
                  const SizedBox(height: 16),
                  Text(t('cases_by_disease'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _BarChart(data: diseaseCount),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static ({DateTime start, DateTime end}) _rangeFor(_Period p, DateTime now) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    if (p == _Period.today) {
      return (start: startOfDay, end: startOfDay.add(const Duration(days: 1)));
    } else if (p == _Period.week) {
      final start = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
      return (start: start, end: start.add(const Duration(days: 7)));
    } else {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return (start: start, end: end);
    }
  }

  static Future<String?> _getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('asha_uid');
  }

  Widget _empty(String text) => Center(child: Text(text));
}

class _KpiRow extends StatelessWidget {
  final int households;
  final int affected;
  const _KpiRow({required this.households, required this.affected});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return Row(
      children: [
        _KpiCard(label: t('kpi_households'), value: households.toString(), color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 12),
        _KpiCard(label: t('kpi_affected'), value: affected.toString(), color: const Color(0xFFEF4444)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.insights_outlined, color: color), const SizedBox(width: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))])
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> data;
  const _BarChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    if (data.isEmpty) return Text(t('no_data'));
    final maxVal = data.values.fold<int>(0, (p, c) => c > p ? c : p);
    return Column(
      children: data.entries.map((e) {
        final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(e.key, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 18, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10))),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(height: 18, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF22C55E)]), borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(e.value.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }
}

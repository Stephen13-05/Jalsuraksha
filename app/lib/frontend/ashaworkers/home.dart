import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/frontend/ashaworkers/reports.dart';
import 'package:app/frontend/ashaworkers/profile.dart';
import 'package:app/frontend/ashaworkers/data_collection.dart';
import 'package:app/frontend/ashaworkers/analytics.dart';
import 'package:app/frontend/ashaworkers/login.dart';
import 'package:app/services/dashboard_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AshaWorkerHomePage extends StatefulWidget {
  final String? userName;
  final String? village;
  final String? district;
  final String? outbreakStage; // e.g., Monitoring / Alert / Outbreak
  final int? reportsSubmitted;
  final String? riskLevel; // 'low' | 'medium' | 'high'

  const AshaWorkerHomePage({
    Key? key,
    this.userName,
    this.village,
    this.district,
    this.outbreakStage,
    this.reportsSubmitted,
    this.riskLevel,
  }) : super(key: key);

  @override
  State<AshaWorkerHomePage> createState() => _AshaWorkerHomePageState();
}

class _AshaWorkerHomePageState extends State<AshaWorkerHomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _dashboard = DashboardService();

  Future<String>? _riskFuture;
  Future<({int daily, int weekly, int monthly})>? _countsFuture;
  Future<List<Map<String, dynamic>>>? _recentReportsFuture;
  Future<({double lat, double lon})?>? _geoFuture;
  Future<({String risk, Map<String, dynamic>? latest, Map<String, dynamic>? daily, List<dynamic>? reasons})>? _villageStatusFuture;
  String? _uid;
  String? _name;
  String? _village;
  String? _district;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  Future<({int daily, int weekly, int monthly})> _fetchVillageCasesCounts(String district, String village) async {
    try {
      // resolve villageId
      final vcol = FirebaseFirestore.instance.collection('appdata').doc('main').collection('villages');
      final q = await vcol.where('name', isEqualTo: village).where('district', isEqualTo: district).limit(1).get();
      if (q.docs.isEmpty) return (daily: 0, weekly: 0, monthly: 0);
      final vid = q.docs.first.id;

      final now = DateTime.now();
      String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      Future<int> sumRange(int days) async {
        int total = 0;
        for (int i = 0; i < days; i++) {
          final d = now.subtract(Duration(days: i));
          final doc = await FirebaseFirestore.instance
              .collection('appdata').doc('main')
              .collection('ashaworkers_daily_cases').doc(ymd(d))
              .collection('villages').doc(vid).get();
          if (doc.exists) total += int.tryParse((doc.data()?['count'] ?? 0).toString()) ?? 0;
        }
        return total;
      }

      final daily = await sumRange(1);
      final weekly = await sumRange(7);
      final monthly = await sumRange(30);
      return (daily: daily, weekly: weekly, monthly: monthly);
    } catch (_) {
      return (daily: 0, weekly: 0, monthly: 0);
    }
  }

  Future<({int today, int week, int month})> _fetchAshaCollectedCounts(String uid) async {
    try {
      final col = FirebaseFirestore.instance
          .collection('appdata')
          .doc('main')
          .collection('ashwadata');
      // fetch recent entries for this worker
      final snap = await col.where('workerId', isEqualTo: uid).limit(500).get();
      final now = DateTime.now();
      final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final weekStart = now.subtract(const Duration(days: 6));
      final monthStart = now.subtract(const Duration(days: 29));
      bool inRange(DateTime d, DateTime start) => !d.isBefore(DateTime(start.year, start.month, start.day));
      int t = 0, w = 0, m = 0;
      for (final d in snap.docs) {
        final data = d.data();
        final ds = (data['date'] ?? todayStr).toString();
        DateTime dt;
        try { dt = DateTime.parse(ds); } catch (_) { continue; }
        if (ds == todayStr) t++;
        if (inRange(dt, weekStart)) w++;
        if (inRange(dt, monthStart)) m++;
      }
      return (today: t, week: w, month: m);
    } catch (_) {
      return (today: 0, week: 0, month: 0);
    }
  }

  Future<({String risk, Map<String, dynamic>? latest, Map<String, dynamic>? daily, List<dynamic>? reasons})> _fetchVillageStatus(String district, String village) async {
    try {
      final col = FirebaseFirestore.instance
          .collection('appdata')
          .doc('main')
          .collection('villages');
      final q = await col
          .where('name', isEqualTo: village)
          .where('district', isEqualTo: district)
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        return (risk: 'green', latest: null, daily: null, reasons: null);
      }
      final base = col.doc(q.docs.first.id);
      final statusDoc = await base.collection('status').doc('current_risk').get();
      final sd = statusDoc.data();
      final risk = (sd?['risk'] ?? 'GREEN').toString().toLowerCase();
      final reasons = (sd?['reason'] as List?)?.cast<dynamic>();
      final latestSnap = await base.collection('hourly').orderBy('timestamp', descending: true).limit(1).get();
      final latest = latestSnap.docs.isNotEmpty ? latestSnap.docs.first.data() : null;
      // today's daily aggregation if available
      final today = DateTime.now();
      final dailyId = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dailyDoc = await base.collection('daily').doc(dailyId).get();
      final daily = dailyDoc.data();
      return (risk: risk, latest: latest, daily: daily, reasons: reasons);
    } catch (_) {
      return (risk: 'green', latest: null, daily: null, reasons: null);
    }
  }

  Future<String?> _fetchUserRisk(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appdata')
          .doc('main')
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() as Map<String, dynamic>?;
      final r = (data?['riskLevel'] ?? data?['risk'] ?? '').toString();
      return r.isNotEmpty ? r : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('asha_uid');
      final spName = prefs.getString('asha_name');
      final spVillage = prefs.getString('asha_village');
      final spDistrict = prefs.getString('asha_district');
      final v = ((widget.village ?? spVillage) ?? '').trim();
      final d = ((widget.district ?? spDistrict) ?? '').trim();
      setState(() {
        _uid = uid;
        _name = (widget.userName ?? spName);
        _village = v.isNotEmpty ? v : null;
        _district = d.isNotEmpty ? d : null;
        // Risk logic: per-user override from Firestore `users/{uid}.riskLevel` if present.
        // Fallback to village/district risk via DashboardService.
        if (uid != null && uid.isNotEmpty) {
          _riskFuture = _fetchUserRisk(uid).then((userRisk) async {
            if (userRisk != null && userRisk.trim().isNotEmpty) return userRisk;
            if (v.isNotEmpty && d.isNotEmpty) {
              return await _dashboard.fetchRiskLevel(district: d, village: v);
            }
            return 'low';
          });
        } else if (v.isNotEmpty && d.isNotEmpty) {
          _riskFuture = _dashboard.fetchRiskLevel(district: d, village: v);
        }
        if (v.isNotEmpty && d.isNotEmpty) {
          _geoFuture = _dashboard.geocodeVillage(village: v, district: d);
          _villageStatusFuture = _fetchVillageStatus(d, v);
        }
        if (uid != null && uid.isNotEmpty) {
          _countsFuture = _computeCounts(uid);
          _recentReportsFuture = _fetchRecentReportsByUser(uid, limit: 5);
        } else {
          _countsFuture = Future.value((daily: 0, weekly: 0, monthly: 0));
          _recentReportsFuture = Future.value(const []);
        }
      });
    } catch (_) {
      setState(() {
        _countsFuture = Future.value((daily: 0, weekly: 0, monthly: 0));
        _recentReportsFuture = Future.value(const []);
      });
    }
  }

  Future<({int daily, int weekly, int monthly})> _computeCounts(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    int daily = 0, weekly = 0, monthly = 0;
    try {
      final col = FirebaseFirestore.instance
          .collection('appdata')
          .doc('main')
          .collection('ashwadata')
          .doc(uid)
          .collection('household_surveys');
      final snap = await col.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth)).get();
      for (final d in snap.docs) {
        final ts = d.data()['createdAt'];
        DateTime when;
        if (ts is Timestamp) when = ts.toDate();
        else if (ts is int) when = DateTime.fromMillisecondsSinceEpoch(ts);
        else if (ts is String) when = DateTime.tryParse(ts) ?? now;
        else when = now;
        if (!when.isBefore(startOfMonth)) monthly++;
        if (!when.isBefore(startOfWeek)) weekly++;
        if (!when.isBefore(startOfDay)) daily++;
      }
    } catch (_) {}
    return (daily: daily, weekly: weekly, monthly: monthly);
  }

  Future<List<Map<String, dynamic>>> _fetchRecentReportsByUser(String uid, {int limit = 5}) async {
    try {
      final col = FirebaseFirestore.instance
          .collection('appdata')
          .doc('main')
          .collection('ashwadata')
          .doc(uid)
          .collection('household_surveys');
      final snap = await col.orderBy('createdAt', descending: true).limit(limit).get();
      return snap.docs.map((d) {
        final data = d.data();
        final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
        final count = (stats['affectedMembers'] ?? stats['totalMembers'] ?? 0) as int;
        return {
          'createdAt': data['createdAt'],
          'count': count,
          'synced': true,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context).t;
    final name = (_name != null && _name!.trim().isNotEmpty)
        ? _name!
        : AppLocalizations.of(context).t('hello_priya').replaceAll('Hello, ', '');
    final village = _village ?? widget.village ?? t('village_rampur');
    final district = _district ?? widget.district ?? t('district_jaipur');
    final stage = widget.outbreakStage ?? 'Monitoring';
    final risk = (widget.riskLevel ?? 'low').toLowerCase();

    Color riskColor;
    String riskLabel;
    switch (risk) {
      case 'high':
      case 'red':
        riskColor = const Color(0xFFEF4444);
        riskLabel = t('risk_high');
        break;
      case 'medium':
      case 'yellow':
        riskColor = const Color(0xFFF59E0B);
        riskLabel = t('risk_medium');
        break;
      default:
        riskColor = const Color(0xFF22C55E);
        riskLabel = t('risk_low');
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          t('nav_home_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Globe language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.public),
            onSelected: (code) {
              switch (code) {
                case 'ne':
                case 'en':
                case 'as':
                case 'hi':
                  LocaleController.instance.setLocale(Locale(code));
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ne', child: Text('नेपाली')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'as', child: Text('অসমীয়া')),
              PopupMenuItem(value: 'hi', child: Text('हिन्दी')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isReturningUser');
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AshaWorkerLoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            const SizedBox(height: 8),
            if (_uid != null) FutureBuilder<({int today, int week, int month})>(
              future: _fetchAshaCollectedCounts(_uid!),
              builder: (context, asnap) {
                if (!asnap.hasData) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your data collected', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(icon: Icons.today, label: 'Today: ${asnap.data!.today}'),
                          _InfoChip(icon: Icons.view_week, label: 'Week: ${asnap.data!.week}'),
                          _InfoChip(icon: Icons.calendar_view_month, label: 'Month: ${asnap.data!.month}'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            if ((_district != null) && (_village != null)) FutureBuilder<({int daily, int weekly, int monthly})>(
              future: _fetchVillageCasesCounts(_district!, _village!),
              builder: (context, csnap) {
                if (!csnap.hasData) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(icon: Icons.local_hospital, label: 'Daily: ${csnap.data!.daily}'),
                      _InfoChip(icon: Icons.view_week, label: 'Weekly: ${csnap.data!.weekly}'),
                      _InfoChip(icon: Icons.calendar_view_month, label: 'Monthly: ${csnap.data!.monthly}'),
                    ],
                  ),
                );
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t('hello')}, $name',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.location_city, label: '${t('village_label')}: $village'),
                      _InfoChip(icon: Icons.map, label: '${t('district_label')}: $district'),
                      _InfoChip(icon: Icons.coronavirus_outlined, label: 'Outbreak: $stage'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Case Count Cards: Daily, Weekly, Monthly
            FutureBuilder<({int daily, int weekly, int monthly})>(
              future: _countsFuture,
              builder: (context, snapshot) {
                final daily = snapshot.data?.daily ?? 0;
                final weekly = snapshot.data?.weekly ?? 0;
                final monthly = snapshot.data?.monthly ?? 0;
                return Row(
                  children: [
                    Expanded(child: _StatCard(title: t('daily_cases'), value: daily.toString(), color: const Color(0xFF0EA5E9))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: t('weekly_cases'), value: weekly.toString(), color: const Color(0xFFF59E0B))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: t('monthly_cases'), value: monthly.toString(), color: const Color(0xFF22C55E))),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Risk Box (dynamic)
            FutureBuilder<String>(
              future: _riskFuture,
              builder: (context, snap) {
                final rr = (snap.data ?? risk).toLowerCase();
                Color rc;
                String rl;
                switch (rr) {
                  case 'high':
                  case 'red':
                    rc = const Color(0xFFEF4444);
                    rl = 'High Risk';
                    break;
                  case 'medium':
                  case 'yellow':
                    rc = const Color(0xFFF59E0B);
                    rl = 'Medium Risk';
                    break;
                  default:
                    rc = const Color(0xFF22C55E);
                    rl = 'Low Risk';
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rc, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: rc),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('$rl ${t('for')} $village',
                            style: TextStyle(color: rc, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Geo Risk Map header
            Text(
              t('geo_risk_map'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Interactive map using flutter_map with risk-colored marker
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: FutureBuilder<({double lat, double lon})?>(
                  future: _geoFuture,
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data == null) {
                      return Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_outlined, color: Color(0xFF9CA3AF), size: 48),
                            const SizedBox(height: 8),
                            Text('$village, $district',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          ],
                        ),
                      );
                    }
                    final pos = LatLng(snap.data!.lat, snap.data!.lon);
                    return FutureBuilder<({String risk, Map<String, dynamic>? latest, Map<String, dynamic>? daily, List<dynamic>? reasons})>(
                      future: _villageStatusFuture,
                      builder: (context, vs) {
                        String r = (vs.data?.risk ?? (risk.isNotEmpty ? risk : 'low')).toLowerCase();
                        Color rc;
                        switch (r) {
                          case 'high':
                          case 'red':
                            rc = const Color(0xFFEF4444);
                            break;
                          case 'medium':
                          case 'yellow':
                            rc = const Color(0xFFF59E0B);
                            break;
                          default:
                            rc = const Color(0xFF22C55E);
                        }

                        return FlutterMap(
                          options: MapOptions(initialCenter: pos, initialZoom: 13),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'app',
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: pos,
                                width: 60,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () => _showRiskDetailsSheet(context, village ?? '-', r, vs.data?.latest, vs.data?.daily, vs.data?.reasons),
                                  child: _RiskMarker(color: rc, animation: _pulseCtrl),
                                ),
                              ),
                            ]),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Latest water metrics card from Firestore (optional if available)
            FutureBuilder<({String risk, Map<String, dynamic>? latest, Map<String, dynamic>? daily, List<dynamic>? reasons})>(
              future: _villageStatusFuture,
              builder: (context, vs) {
                if (!vs.hasData || vs.data?.latest == null) return const SizedBox.shrink();
                final latest = vs.data!.latest!;
                final ph = latest['ph'];
                final turb = latest['turbidity'];
                final ecoli = latest['ecoli'] == true;
                final cases = latest['daily_cases'] ?? 0;
                final daily = vs.data!.daily;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(icon: Icons.science, label: 'pH: ${ph ?? '-'}'),
                          _InfoChip(icon: Icons.opacity, label: 'NTU: ${turb ?? '-'}'),
                          _InfoChip(icon: Icons.bloodtype, label: 'E. coli: ${ecoli ? 'Yes' : 'No'}'),
                          _InfoChip(icon: Icons.local_hospital, label: 'Cases: $cases'),
                        ],
                      ),
                      if (daily != null) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _metricChip(Icons.grain, 'Daily Rain', '${daily['rainfall_total_mm'] ?? 0} mm'),
                          _metricChip(Icons.timeline, 'Avg pH', '${daily['avg_ph'] ?? '-'}'),
                          _metricChip(Icons.stacked_line_chart, 'Avg NTU', '${daily['avg_turbidity'] ?? '-'}'),
                          _metricChip(Icons.check_circle, 'E. coli (daily)', (daily['ecoli_present'] == true) ? 'Present' : 'Absent'),
                        ]),
                      ]
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final vs = await _villageStatusFuture;
                _showRiskDetailsSheet(context, village ?? '-', vs?.risk ?? 'green', vs?.latest, vs?.daily, vs?.reasons);
              },
              child: Center(
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Reports header
            Text(
              t('recent_reports'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Recent report items (dynamic)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _recentReportsFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Text(t('no_recent_reports'), style: TextStyle(color: Colors.grey.shade600));
                }
                return Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      _ReportRow(
                        dateTime: _fmtDate(items[i]['createdAt']),
                        subText: '${items[i]['count'] ?? items[i]['cases'] ?? 0} ' + AppLocalizations.of(context).t('reports_collected_suffix'),
                        synced: (items[i]['synced'] ?? true) == true,
                      ),
                      if (i != items.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),

      // Bottom Navigation (5 tabs)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AshaWorkerDataCollectionPage(),
                ),
              );
            } else if (i == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AshaWorkerReportsPage(),
                ),
              );
            } else if (i == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AshaWorkerAnalyticsPage(),
                ),
              );
            } else if (i == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AshaWorkerProfilePage(),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: cs.primary,
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
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _riskColorFrom(String r) {
    switch (r.toLowerCase()) {
      case 'high':
      case 'red':
        return const Color(0xFFEF4444);
      case 'medium':
      case 'yellow':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _riskLabelFrom(String r) {
    switch (r.toLowerCase()) {
      case 'high':
      case 'red':
        return 'High Risk';
      case 'medium':
      case 'yellow':
        return 'Medium Risk';
      default:
        return 'Low Risk';
    }
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _showRiskDetailsSheet(
    BuildContext context,
    String village,
    String risk,
    Map<String, dynamic>? latest,
    Map<String, dynamic>? daily,
    List<dynamic>? reasons,
  ) {
    final rc = _riskColorFrom(risk);
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: rc.withOpacity(0.12),
                      border: Border.all(color: rc),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Icon(Icons.shield, color: rc, size: 16),
                      const SizedBox(width: 6),
                      Text(_riskLabelFrom(risk), style: TextStyle(color: rc, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded))
                ],
              ),
              const SizedBox(height: 10),
              Text('${AppLocalizations.of(context).t('geo_risk_map')}: $village', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              if (latest != null) Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _metricChip(Icons.science, 'pH', (latest['ph'] ?? '-').toString()),
                  _metricChip(Icons.opacity, 'NTU', (latest['turbidity'] ?? '-').toString()),
                  _metricChip(Icons.bloodtype, 'E. coli', (latest['ecoli'] == true) ? 'Present' : 'Absent'),
                  _metricChip(Icons.local_hospital, 'Cases', (latest['daily_cases'] ?? 0).toString()),
                ],
              ) else Text(AppLocalizations.of(context).t('no_data')),
              if (daily != null) ...[
                const SizedBox(height: 14),
                const Text('Today\'s Aggregates', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _metricChip(Icons.grain, 'Rain (mm)', '${daily['rainfall_total_mm'] ?? 0}'),
                  _metricChip(Icons.timeline, 'Avg pH', '${daily['avg_ph'] ?? '-'}'),
                  _metricChip(Icons.stacked_line_chart, 'Avg NTU', '${daily['avg_turbidity'] ?? '-'}'),
                  _metricChip(Icons.verified, 'E. coli (daily)', (daily['ecoli_present'] == true) ? 'Present' : 'Absent'),
                ]),
              ],
              if (reasons != null && reasons.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Contributing factors', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reasons.map((r) => _metricChip(Icons.info_outline, 'Reason', r.toString())).toList().cast<Widget>(),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

}

class _RiskMarker extends StatelessWidget {
  final Color color;
  final Animation<double> animation;
  const _RiskMarker({required this.color, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value; // 0..1
        final outerSize = 46 + 14 * t;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.10 * opacity),
                border: Border.all(color: color.withOpacity(0.5 * opacity), width: 2),
              ),
            ),
            // Core glow
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withOpacity(0.35), color.withOpacity(0.15)], radius: 0.85),
                border: Border.all(color: color, width: 2),
              ),
            ),
            // Pin icon
            Icon(Icons.location_on, color: color, size: 26),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.insert_chart_outlined_rounded, color: color),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

String _fmtDate(dynamic ts) {
  try {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return _format(d);
    } else if (ts is int) {
      return _format(DateTime.fromMillisecondsSinceEpoch(ts));
    } else if (ts is String) {
      return _format(DateTime.tryParse(ts) ?? DateTime.now());
    }
  } catch (_) {}
  return _format(DateTime.now());
}

String _format(DateTime d) {
  // Simple formatted date
  return '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _month(int m) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[(m - 1).clamp(0, 11)];
}

class _LinkPill extends StatelessWidget {
  final String text;
  const _LinkPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: cs.primary,
        decoration: TextDecoration.underline,
        decorationColor: cs.primary,
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '|',
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String dateTime;
  final String subText;
  final bool synced;

  const _ReportRow({
    super.key,
    required this.dateTime,
    required this.subText,
    required this.synced,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = synced
        ? AppLocalizations.of(context).t('synced')
        : AppLocalizations.of(context).t('not_synced');
    final bgColor = synced ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateTime,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subText,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Right status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
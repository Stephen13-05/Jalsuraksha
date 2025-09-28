import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/frontend/ashaworkers/reports.dart';
import 'package:app/frontend/ashaworkers/profile.dart';
import 'package:app/frontend/ashaworkers/data_collection.dart';
import 'package:app/frontend/ashaworkers/login.dart';
import 'package:app/frontend/ashaworkers/navigation.dart';
import 'package:app/frontend/ashaworkers/bluetooth_sync.dart';
import 'package:app/frontend/ashaworkers/offline_sync.dart';
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

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InsightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  final String title;
  final num households;
  final bool synced;
  final String village;
  final String riskLabel;
  final Color riskColor;
  final VoidCallback onTap;

  const _RecentReportCard({
    required this.title,
    required this.households,
    required this.synced,
    required this.village,
    required this.riskLabel,
    required this.riskColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    village,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riskLabel,
                    style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    households.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0EA5E9)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Households', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      Text(
                        'Status: ${synced ? 'Synced' : 'Pending'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AshaWorkerHomePageState extends State<AshaWorkerHomePage> with SingleTickerProviderStateMixin {
  AshaNavTab _currentTab = AshaNavTab.home;
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
          _recentReportsFuture = _fetchRecentReportsByUser(uid, limit: 3);
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
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.85),
            ]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          t('nav_home_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
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
      drawer: AshaNavDrawer(
        currentTab: _currentTab,
        onSelectTab: _handleNavSelection,
        onBluetoothSync: _openBluetoothSync,
        onOfflineSync: _openOfflineSync,
        onChangeLanguage: () => showLanguagePicker(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.28),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.22),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.45)),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Today', value: daily.toString(), color: const Color(0xFF0EA5E9))),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(title: 'This Week', value: weekly.toString(), color: const Color(0xFFF59E0B))),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(title: 'This Month', value: monthly.toString(), color: const Color(0xFF22C55E))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Key insights', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _InsightRow(icon: Icons.trending_up, text: 'Daily collections are up to $daily households today.'),
                          _InsightRow(icon: Icons.timeline, text: 'Weekly follow-ups completed: $weekly households.'),
                          _InsightRow(icon: Icons.task_alt, text: 'Monthly coverage: $monthly home visits recorded.'),
                        ],
                      ),
                    ),
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
                    gradient: LinearGradient(colors: [rc.withOpacity(0.35), rc.withOpacity(0.20)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rc, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: rc, size: 28),
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
                        if (!vs.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final data = vs.data;
                        final resolvedRisk = (data?.risk ?? risk).toLowerCase();
                        final markerColor = _riskColorFrom(resolvedRisk);
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
                                width: 100,
                                height: 100,
                                child: GestureDetector(
                                  onTap: () => _showRiskDetailsSheet(
                                    context,
                                    village ?? '-',
                                    resolvedRisk,
                                    data?.latest,
                                    data?.daily,
                                    data?.reasons,
                                  ),
                                  child: _RiskMarker(color: markerColor, animation: _pulseCtrl),
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

            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final vs = await _villageStatusFuture;
                _showRiskDetailsSheet(context, village ?? '-', (vs?.risk ?? risk).toLowerCase(), vs?.latest, vs?.daily, vs?.reasons);
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
                final list = items.take(3).toList();
                return Column(
                  children: [
                    for (final item in list)
                      Builder(
                        builder: (ctx) {
                          final itemRisk = (item['riskLevel'] ?? risk).toString();
                          final itemColor = _riskColorFrom(itemRisk);
                          final itemLabel = _riskLabelFrom(itemRisk);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecentReportCard(
                              title: _fmtDate(item['createdAt']),
                              households: (item['count'] ?? item['cases'] ?? 0) as num,
                              synced: (item['synced'] ?? true) == true,
                              village: (item['village'] ?? village ?? '-') as String,
                              riskLabel: itemLabel,
                              riskColor: itemColor,
                              onTap: () => _showReportDetailsBottomSheet(context, Map<String, dynamic>.from(item)),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _handleNavSelection(AshaNavTab tab) {
    if (tab == _currentTab) return;
    switch (tab) {
      case AshaNavTab.home:
        setState(() => _currentTab = AshaNavTab.home);
        break;
      case AshaNavTab.dataCollection:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerDataCollectionPage()),
        );
        break;
      case AshaNavTab.reports:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerReportsPage()),
        );
        break;
      case AshaNavTab.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerProfilePage()),
        );
        break;
    }
  }

  void _openBluetoothSync() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AshaWorkerBluetoothSyncPage()),
    );
  }

  void _openOfflineSync() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AshaWorkerOfflineSyncPage()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    // Colorize chip based on label/value, without changing content
    final l = label.toLowerCase();
    Color bg = const Color(0xFFF8FAFC);
    Color ic = const Color(0xFF64748B);
    if (l.contains('ph')) {
      bg = const Color(0xFFE0F2FE); // sky-100
      ic = const Color(0xFF0EA5E9); // sky-500
    } else if (l.contains('ntu')) {
      bg = const Color(0xFFE6FFFA); // teal-50
      ic = const Color(0xFF14B8A6); // teal-500
    } else if (l.contains('e. coli')) {
      final yes = value.toLowerCase().startsWith('y');
      bg = yes ? const Color(0xFFFFE4E6) : const Color(0xFFECFDF5); // red-100 or emerald-50
      ic = yes ? const Color(0xFFEF4444) : const Color(0xFF22C55E); // red-500 or emerald-500
    } else if (l.contains('cases')) {
      bg = const Color(0xFFFFFBEB); // amber-50
      ic = const Color(0xFFF59E0B); // amber-500
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ic.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: ic),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: ic.withOpacity(0.9), fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
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

  void _showReportDetailsBottomSheet(BuildContext context, Map<String, dynamic> report) {
    final t = AppLocalizations.of(context).t;
    final createdAt = _fmtDate(report['createdAt']);
    final households = (report['count'] ?? report['cases'] ?? 0).toString();
    final synced = (report['synced'] ?? true) == true;
    final riskValue = (report['riskLevel'] ?? '').toString();
    final color = _riskColorFrom(riskValue.isEmpty ? 'low' : riskValue);
    final riskLabel = _riskLabelFrom(riskValue.isEmpty ? 'low' : riskValue);
    final village = report['village']?.toString() ?? (_village ?? '-');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(riskLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(t('recent_report_details'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _kvRow(t('village'), village),
                _kvRow(t('submitted_on'), createdAt),
                _kvRow(t('household_count'), households),
                _kvRow(t('status'), synced ? t('synced') : t('not_synced')),
                if (report['notes'] != null) _kvRow(t('notes'), report['notes'].toString()),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(t('view_full_report')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kvRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
        final outerSize = 86 + 22 * t; // bigger pulse
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withOpacity(0.35), color.withOpacity(0.15)], radius: 0.85),
                border: Border.all(color: color, width: 2),
              ),
            ),
            // Pin icon
            Icon(Icons.location_on, color: color, size: 34),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.75),
        ]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insert_chart_outlined_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          bgColor.withOpacity(0.30),
          bgColor.withOpacity(0.18),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withOpacity(0.60)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
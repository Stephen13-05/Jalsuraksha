import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/frontend/ashaworkers/home.dart';
import 'package:app/frontend/ashaworkers/data_collection.dart';
import 'package:app/frontend/ashaworkers/profile.dart';
import 'package:app/frontend/ashaworkers/analytics.dart';

class AshaWorkerReportsPage extends StatefulWidget {
  const AshaWorkerReportsPage({super.key});

  @override
  State<AshaWorkerReportsPage> createState() => _AshaWorkerReportsPageState();
}

// Date formatting helpers
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

class _AshaWorkerReportsPageState extends State<AshaWorkerReportsPage> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(t('my_reports'), style: const TextStyle(fontWeight: FontWeight.w700)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              color: cs.primary,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: t('tab_today')),
                  Tab(text: t('tab_this_week')),
                  Tab(text: t('tab_this_month')),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportTab(period: _Period.today),
            _ReportTab(period: _Period.week),
            _ReportTab(period: _Period.month),
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
              } else if (i == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaWorkerAnalyticsPage()),
                );
              } else if (i == 4) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaWorkerProfilePage()),
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
      ),
    );
  }
}

enum _Period { today, week, month }

class _ReportTab extends StatefulWidget {
  final _Period period;
  const _ReportTab({required this.period});

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  bool _affectedOnly = false;
  bool _syncedOnly = false;
  String? _disease;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return FutureBuilder<String?>(
      future: _getUid(),
      builder: (context, snap) {
        final uid = snap.data;
        if (uid == null || uid.isEmpty) return _emptyState(t('no_recent_reports'));
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
            final range = _rangeFor(widget.period, now);
            // Within range
            var items = docs.where((d) {
              final ts = d.data()['createdAt'];
              DateTime when;
              if (ts is Timestamp) when = ts.toDate();
              else if (ts is int) when = DateTime.fromMillisecondsSinceEpoch(ts);
              else if (ts is String) when = DateTime.tryParse(ts) ?? now;
              else when = now;
              return !when.isBefore(range.start) && when.isBefore(range.end);
            }).toList();

            // Build distinct diseases for dropdown
            final diseaseSet = <String>{};
            for (final d in items) {
              final members = (d.data()['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              for (final m in members) {
                if (m['affected'] == true) {
                  final dis = (m['disease'] as String?)?.trim();
                  if (dis != null && dis.isNotEmpty) diseaseSet.add(dis);
                }
              }
            }

            // Apply UI filters
            if (_affectedOnly) {
              items = items.where((d) {
                final members = (d.data()['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                return members.any((m) => m['affected'] == true);
              }).toList();
            }
            if (_disease != null && _disease!.isNotEmpty) {
              items = items.where((d) {
                final members = (d.data()['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                return members.any((m) => m['affected'] == true && (m['disease'] ?? '') == _disease);
              }).toList();
            }
            if (_syncedOnly) {
              items = items.where((d) => !d.metadata.hasPendingWrites).toList();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _FilterBar(
                  affectedOnly: _affectedOnly,
                  syncedOnly: _syncedOnly,
                  disease: _disease,
                  diseases: diseaseSet.toList()..sort(),
                  onChanged: (a, s, dis) => setState(() {
                    _affectedOnly = a; _syncedOnly = s; _disease = dis;
                  }),
                  onClear: () => setState(() { _affectedOnly = false; _syncedOnly = false; _disease = null; }),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty) _emptyState(t('no_recent_reports')),
                for (int i = 0; i < items.length; i++) ...[
                  _FancyReportCard(doc: items[i]),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static Future<String?> _getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('asha_uid');
  }

  static ({DateTime start, DateTime end}) _rangeFor(_Period p, DateTime now) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    if (p == _Period.today) {
      return (start: startOfDay, end: startOfDay.add(const Duration(days: 1)));
    } else if (p == _Period.week) {
      final weekday = startOfDay.weekday;
      final start = startOfDay.subtract(Duration(days: weekday - 1));
      return (start: start, end: start.add(const Duration(days: 7)));
    } else {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return (start: start, end: end);
    }
  }
}

class _SyncedPill extends StatelessWidget {
  final String text;
  final Color color;
  const _SyncedPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ReportCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context).t;
    final data = doc.data();
    final hh = (data['household'] as Map?)?.cast<String, dynamic>() ?? {};
    final members = (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    String affectedPerson = 'None';
    String disease = '-';
    for (final m in members) {
      if (m['affected'] == true) {
        affectedPerson = (m['name'] as String?) ?? 'Unknown';
        disease = (m['disease'] as String?) ?? 'Unknown';
        break;
      }
    }
    final ts = data['createdAt'];
    final dateStr = _fmtDate(ts);

    return Card(
      elevation: 0.5,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, data),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hh['state'] ?? '-'}, ${hh['district'] ?? '-'}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('village_label')}: ${hh['village'] ?? '-'} • ${t('door_no')}: ${hh['doorNo'] ?? '-'}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('head')}: ${hh['headName'] ?? '-'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${t('affected')}: $affectedPerson • ${t('disease')}: $disease', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Builder(builder: (context) {
                final synced = !(doc.metadata.hasPendingWrites);
                final label = synced ? AppLocalizations.of(context).t('synced') : AppLocalizations.of(context).t('not_synced');
                final color = synced ? cs.primary : const Color(0xFFEF4444);
                return _SyncedPill(text: label, color: color);
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final t = AppLocalizations.of(context).t;
    final hh = (data['household'] as Map?)?.cast<String, dynamic>() ?? {};
    final members = (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('household_details'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${t('head')}: ${hh['headName'] ?? '-'}'),
                Text('${t('door_no')}: ${hh['doorNo'] ?? '-'}'),
                Text('${t('village')}: ${hh['village'] ?? '-'}'),
                Text('${t('district')}: ${hh['district'] ?? '-'}'),
                Text('${t('phone')}: ${hh['phone'] ?? '-'}'),
                const SizedBox(height: 12),
                Text(t('members'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final m in members) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${t('age')}: ${m['age'] ?? '-'} • ${t('gender')}: ${m['gender'] ?? '-'}'),
                        Text('${t('phone')}: ${m['phone'] ?? '-'}'),
                        Text('${t('affected')}: ${m['affected'] == true ? t('yes') : t('no')}'),
                        if (m['affected'] == true) Text('${t('disease')}: ${m['disease'] ?? '-'}'),
                        if ((m['symptoms'] ?? '').toString().isNotEmpty) Text('${t('symptoms_hint')}: ${m['symptoms']}'),
                        if ((m['notes'] ?? '').toString().isNotEmpty) Text('${t('dc_notes')}: ${m['notes']}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _emptyState(String text) => Center(child: Text(text, style: const TextStyle(color: Color(0xFF6B7280))));

// Filter bar widget
class _FilterBar extends StatelessWidget {
  final bool affectedOnly;
  final bool syncedOnly;
  final String? disease;
  final List<String> diseases;
  final void Function(bool affectedOnly, bool syncedOnly, String? disease) onChanged;
  final VoidCallback onClear;
  const _FilterBar({
    required this.affectedOnly,
    required this.syncedOnly,
    required this.disease,
    required this.diseases,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context).t;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(value: affectedOnly, onChanged: (v) => onChanged(v, syncedOnly, disease)),
                    const SizedBox(width: 4),
                    Text(t('filter_affected_only')),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Switch(value: syncedOnly, onChanged: (v) => onChanged(affectedOnly, v, disease)),
                    const SizedBox(width: 4),
                    Text(t('filter_synced_only')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: t('filter_disease'), border: const OutlineInputBorder()),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: disease != null && diseases.contains(disease) ? disease : null,
                      hint: Text(t('all_diseases')),
                      isExpanded: true,
                      items: [
                        for (final d in diseases)
                          DropdownMenuItem(value: d, child: Text(d)),
                      ],
                      onChanged: (v) => onChanged(affectedOnly, syncedOnly, v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: onClear, icon: Icon(Icons.filter_alt_off, color: cs.primary), label: Text(t('clear'))),
            ],
          ),
        ],
      ),
    );
  }
}

// Modern report card
class _FancyReportCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _FancyReportCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = doc.data();
    final hh = (data['household'] as Map?)?.cast<String, dynamic>() ?? {};
    final members = (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    String affectedPerson = 'None';
    String disease = '-';
    for (final m in members) {
      if (m['affected'] == true) { affectedPerson = (m['name'] as String?) ?? 'Unknown'; disease = (m['disease'] as String?) ?? 'Unknown'; break; }
    }
    final ts = data['createdAt'];
    final dateStr = _fmtDate(ts);
    final synced = !(doc.metadata.hasPendingWrites);

    return InkWell(
      onTap: () => _showDetails(context, data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary.withOpacity(0.18), cs.primary.withOpacity(0.06)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Head: ${hh['headName'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${hh['district'] ?? '-'} • ${hh['village'] ?? '-'} • Door: ${hh['doorNo'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  _SyncedPill(text: synced ? AppLocalizations.of(context).t('synced') : AppLocalizations.of(context).t('not_synced'), color: synced ? cs.primary : const Color(0xFFEF4444)),
                ],
              ),
            ),
            // body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Affected: $affectedPerson • Disease: $disease', style: const TextStyle(color: Color(0xFF374151)))),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;
    final hh = (data['household'] as Map?)?.cast<String, dynamic>() ?? {};
    final members = (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      const Text('Household Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _kv('Head', hh['headName']),
                  _kv('Door No', hh['doorNo']),
                  _kv('Village', hh['village']),
                  _kv('District', hh['district']),
                  _kv('Phone', hh['phone']),
                  const SizedBox(height: 12),
                  const Text('Members', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final m in members) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0,2))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Expanded(child: Text(m['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800))), if (m['affected'] == true) _chip('Affected', const Color(0xFFEF4444))]),
                          const SizedBox(height: 4),
                          Text('Age: ${m['age'] ?? '-'} • Gender: ${m['gender'] ?? '-'}', style: const TextStyle(color: Color(0xFF6B7280))),
                          if ((m['phone'] ?? '').toString().isNotEmpty) Text('Phone: ${m['phone']}', style: const TextStyle(color: Color(0xFF6B7280))),
                          if (m['affected'] == true && (m['disease'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: _chip(m['disease'], cs.primary)),
                          if ((m['symptoms'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Symptoms: ${m['symptoms']}', style: const TextStyle(color: Color(0xFF374151)))),
                          if ((m['notes'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Notes: ${m['notes']}', style: const TextStyle(color: Color(0xFF374151)))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, dynamic v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [SizedBox(width: 96, child: Text('$k:', style: const TextStyle(color: Color(0xFF6B7280)))), Expanded(child: Text((v ?? '-').toString()))]),
      );

  Widget _chip(dynamic label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.12), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
        child: Text('$label', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

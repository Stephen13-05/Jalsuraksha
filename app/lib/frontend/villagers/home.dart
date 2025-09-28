import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/services/dashboard_service.dart';
import 'package:app/services/villager_data_service.dart';

class VillagerHomeTab extends StatefulWidget {
  const VillagerHomeTab({
    super.key,
    required this.uid,
    required this.fullName,
    required this.village,
    required this.district,
  });

  final String uid;
  final String fullName;
  final String village;
  final String district;

  @override
  State<VillagerHomeTab> createState() => _VillagerHomeTabState();
}

class _VillagerHomeTabState extends State<VillagerHomeTab> with SingleTickerProviderStateMixin {
  final _dashboard = DashboardService();
  final _dataService = VillagerDataService();

  Future<String>? _riskFuture;
  Future<({double lat, double lon})?>? _geoFuture;
  Future<List<Map<String, dynamic>>>? _issuesFuture;
  Future<({int daily, int weekly, int monthly})>? _countsFuture;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _riskFuture = _dashboard.fetchRiskLevel(district: widget.district, village: widget.village);
    _geoFuture = _dashboard.geocodeVillage(village: widget.village, district: widget.district);
    _issuesFuture = _dataService.fetchRecentIssues(uid: widget.uid, limit: 3);
    _countsFuture = _dashboard.fetchCaseCounts(village: widget.village);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(theme),
            const SizedBox(height: 20),
            _buildCaseSummary(),
            const SizedBox(height: 20),
            _buildRiskCard(),
            const SizedBox(height: 16),
            _buildRiskMap(),
            const SizedBox(height: 12),
            _buildRecentReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.28),
            theme.colorScheme.secondary.withOpacity(0.22),
            const Color(0xFF9333EA).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.32)),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello ${widget.fullName.split(' ').first},',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay updated about water safety in your village and act quickly when you spot an issue.',
            style: TextStyle(color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(icon: Icons.location_city, label: 'Village: ${widget.village}'),
              _InfoChip(icon: Icons.map_outlined, label: 'District: ${widget.district}'),
              _InfoChip(icon: Icons.shield_moon_outlined, label: 'Safe Water Champion'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaseSummary() {
    return FutureBuilder<({int daily, int weekly, int monthly})>(
      future: _countsFuture,
      builder: (context, snapshot) {
        final daily = snapshot.data?.daily ?? 0;
        final weekly = snapshot.data?.weekly ?? 0;
        final monthly = snapshot.data?.monthly ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Snapshot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today',
                    value: daily.toString(),
                    gradient: const [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'This Week',
                    value: weekly.toString(),
                    gradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'This Month',
                    value: monthly.toString(),
                    gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiskCard() {
    return FutureBuilder<String>(
      future: _riskFuture,
      builder: (context, snapshot) {
        final risk = snapshot.data ?? 'low';
        final color = _riskColor(risk);
        final label = _riskLabel(risk);
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.22), color.withOpacity(0.12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.6), width: 1.4),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 52 + (_pulseController.value * 8),
                        height: 52 + (_pulseController.value * 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.18 * (1 - _pulseController.value)),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: color.shade900OrDefault(), fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Current water health status for ${widget.village}. Stay alert and follow hygiene guidelines.',
                      style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Village Risk Map',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FutureBuilder<({double lat, double lon})?>(
              future: _geoFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 52, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        Text('${widget.village}, ${widget.district}', style: const TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        const Text('Risk map will appear once connectivity is available.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }
                final position = LatLng(snapshot.data!.lat, snapshot.data!.lon);
                return FutureBuilder<String>(
                  future: _riskFuture,
                  builder: (context, snap) {
                    final risk = snap.data ?? 'low';
                    final color = _riskColor(risk);
                    return FlutterMap(
                      options: MapOptions(initialCenter: position, initialZoom: 13),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'jal_suraksha_villagers',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: position,
                            width: 80,
                            height: 80,
                            child: _RiskMarker(gradientColor: color, animation: _pulseController),
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
      ],
    );
  }

  Widget _buildRecentReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _issuesFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No reports submitted yet. Tap "Sanitation Issues" to report a new problem.'),
              );
            }
            return Column(
              children: [
                for (final issue in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentIssueCard(issue: issue),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  MaterialColor _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
      case 'red':
        return Colors.red;
      case 'medium':
      case 'yellow':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _riskLabel(String risk) {
    switch (risk.toLowerCase()) {
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.gradient});

  final String title;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _RiskMarker extends StatelessWidget {
  const _RiskMarker({required this.gradientColor, required this.animation});

  final MaterialColor gradientColor;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1 + (animation.value * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [gradientColor.shade500, gradientColor.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColor.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 22),
          ),
        );
      },
    );
  }
}

class _RecentIssueCard extends StatelessWidget {
  const _RecentIssueCard({required this.issue});

  final Map<String, dynamic> issue;

  @override
  Widget build(BuildContext context) {
    final createdAt = issue['createdAt'];
    String formattedDate = 'Just now';
    if (createdAt is DateTime) {
      formattedDate = _formatDate(createdAt);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.report_gmailerrorred_outlined, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['title']?.toString() ?? 'Issue reported',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  issue['description']?.toString() ?? 'Description unavailable.',
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.watch_later_outlined, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const Spacer(),
                    Text(
                      issue['category']?.toString().toUpperCase() ?? 'GENERAL',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

extension on MaterialColor {
  Color shade900OrDefault() {
    return this[900] ?? this[700] ?? this[500] ?? Colors.black87;
  }
}

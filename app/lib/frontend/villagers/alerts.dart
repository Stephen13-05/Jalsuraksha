import 'package:flutter/material.dart';
import 'package:app/services/villager_data_service.dart';

class VillagerAlertsTab extends StatefulWidget {
  const VillagerAlertsTab({super.key, required this.village, required this.district});

  final String village;
  final String district;

  @override
  State<VillagerAlertsTab> createState() => _VillagerAlertsTabState();
}

class _VillagerAlertsTabState extends State<VillagerAlertsTab> {
  final _dataService = VillagerDataService();
  late final Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _dataService.fetchVillageAlerts(
      village: widget.village,
      district: widget.district,
      limit: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data ?? const [];
        if (alerts.isEmpty) {
          return const _EmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlertCard(alert: alert, index: index),
            );
          },
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.index});

  final Map<String, dynamic> alert;
  final int index;

  @override
  Widget build(BuildContext context) {
    final severity = (alert['severity'] ?? 'medium').toString().toLowerCase();
    final color = _severityColor(severity, index);
    final createdAt = alert['createdAt'];
    String subtitle = '';
    if (createdAt is DateTime) {
      subtitle = _formatDate(createdAt);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_severityIcon(severity), color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title']?.toString() ?? 'Stay alert',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827)),
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alert['description']?.toString() ?? 'Follow hygiene guidance and stay tuned for updates.',
                    style: const TextStyle(color: Color(0xFF1F2937), height: 1.4),
                  ),
                  if (alert['callToAction'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        alert['callToAction'].toString(),
                        style: TextStyle(color: color, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity, int index) {
    switch (severity) {
      case 'high':
      case 'red':
        return const Color(0xFFDC2626);
      case 'medium':
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'low':
      case 'green':
        return const Color(0xFF15803D);
      default:
        const palette = [
          Color(0xFF2563EB),
          Color(0xFF7C3AED),
          Color(0xFFEA580C),
        ];
        return palette[index % palette.length];
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'high':
      case 'red':
        return Icons.error_outline;
      case 'medium':
      case 'yellow':
        return Icons.warning_amber_outlined;
      case 'low':
      case 'green':
        return Icons.info_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 1) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} min ago';
    }
    return 'Just now';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('All clear! No alerts available.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              'Stay tuned for real-time updates about water safety and sanitation in your village.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

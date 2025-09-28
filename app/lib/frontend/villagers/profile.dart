import 'package:flutter/material.dart';

class VillagerProfilePage extends StatelessWidget {
  const VillagerProfilePage({
    super.key,
    required this.uid,
    required this.fullName,
    required this.village,
    required this.district,
    this.state,
    this.phoneNumber,
  });

  final String uid;
  final String fullName;
  final String village;
  final String district;
  final String? state;
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <_ProfileDetail>[ 
      _ProfileDetail(label: 'UID', value: uid, icon: Icons.fingerprint),
      _ProfileDetail(label: 'Full Name', value: fullName, icon: Icons.person_outline),
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        _ProfileDetail(label: 'Phone', value: phoneNumber!, icon: Icons.phone_outlined),
      _ProfileDetail(label: 'Village', value: village, icon: Icons.home_outlined),
      _ProfileDetail(label: 'District', value: district, icon: Icons.location_city_outlined),
      if (state != null && state!.trim().isNotEmpty)
        _ProfileDetail(label: 'State', value: state!, icon: Icons.map_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$village, $district',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (state != null && state!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      state!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final item in details)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProfileTile(detail: item),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_outlined, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your details help us personalize alerts and ensure quick response to sanitation issues.',
                      style: TextStyle(color: Color(0xFF0F172A), height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetail {
  const _ProfileDetail({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.detail});

  final _ProfileDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(detail.icon, color: const Color(0xFF0EA5E9)),
        ),
        title: Text(
          detail.label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          detail.value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

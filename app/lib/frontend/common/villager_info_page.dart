import 'package:flutter/material.dart';

class VillagerInfoPage extends StatelessWidget {
  const VillagerInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Villagers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0EA5E9),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'Learn'),
              Tab(icon: Icon(Icons.report_problem_outlined), text: 'Report'),
              Tab(icon: Icon(Icons.water_drop_outlined), text: 'Resources'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LearnTab(),
            _ReportTab(),
            _ResourcesTab(),
          ],
        ),
      ),
    );
  }
}

class _LearnTab extends StatelessWidget {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tipCard(
            title: 'Clean Water Practices',
            color: const Color(0xFF10B981),
            text:
                'Boil water for at least 1 minute before drinking. Use covered containers and avoid mixing clean and dirty water.',
          ),
          const SizedBox(height: 12),
          _tipCard(
            title: 'Hygiene & Sanitation',
            color: const Color(0xFFF59E0B),
            text: 'Wash hands with soap for 20 seconds, especially before eating and after using the toilet.',
          ),
          const SizedBox(height: 12),
          _tipCard(
            title: 'Early Symptoms',
            color: const Color(0xFF6366F1),
            text: 'Watch for diarrhea, vomiting, fever, stomach pain. Seek clinic help immediately if symptoms appear.',
          ),
        ],
      ),
    );
  }

  Widget _tipCard({required String title, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.darken(),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF334155), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Water Issue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Village/Area',
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Describe the issue (e.g., muddy water, smell, illness cases)',
              prefixIcon: const Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue submitted. Thank you for keeping your community safe!')),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ResourceTile(
          title: 'Nearest Clinic Finder',
          subtitle: 'Locate local clinics for quick treatment and advice',
          icon: Icons.local_hospital_outlined,
          color: Color(0xFF10B981),
        ),
        _ResourceTile(
          title: 'Safe Water Checklist',
          subtitle: 'Daily checklist to ensure drinking water safety at home',
          icon: Icons.checklist_outlined,
          color: Color(0xFF0EA5E9),
        ),
        _ResourceTile(
          title: 'Emergency Contacts',
          subtitle: 'Important numbers for health and water supply emergencies',
          icon: Icons.phone_in_talk_outlined,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ResourceTile({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

extension _ColorX on Color {
  Color darken([double amount = .15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

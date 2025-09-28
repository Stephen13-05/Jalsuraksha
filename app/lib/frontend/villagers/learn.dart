import 'package:flutter/material.dart';

class VillagerLearnTab extends StatelessWidget {
  const VillagerLearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = _createTips();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _LearnCard(content: tip),
        );
      },
    );
  }

  List<_LearnContent> _createTips() {
    return const [
      _LearnContent(
        title: 'Daily Safe Water Habits',
        description:
            '• Boil drinking water for at least 1 minute and store it in a covered container.\n• Separate clean and used utensils.\n• Wash raw fruits and vegetables thoroughly before use.',
        gradient: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
        icon: Icons.water_drop_outlined,
      ),
      _LearnContent(
        title: 'Hygiene & Sanitation',
        description:
            '• Wash hands with soap for 20 seconds, especially before meals and after using the toilet.\n• Keep toilets and washing areas dry and clean.\n• Avoid open defecation to protect groundwater.\n• Dispose of household waste away from water sources.',
        gradient: [Color(0xFF34D399), Color(0xFF059669)],
        icon: Icons.clean_hands_outlined,
      ),
      _LearnContent(
        title: 'Recognize Early Symptoms',
        description:
            '• Sudden diarrhea, vomiting, stomach cramps, or fever can indicate waterborne illness.\n• Ensure the sick person stays hydrated with ORS (Oral Rehydration Solution).\n• Visit the nearest clinic immediately if symptoms persist.',
        gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
        icon: Icons.medical_services_outlined,
      ),
      _LearnContent(
        title: 'Prevent Stagnant Water',
        description:
            '• Cover or empty water containers regularly to prevent mosquito breeding.\n• Fill potholes or puddle-prone areas with sand or gravel.\n• Report clogged drainage or leaks to local sanitation officers.',
        gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        icon: Icons.eco_outlined,
      ),
      _LearnContent(
        title: 'Emergency Checklist',
        description:
            '• Keep ORS sachets, clean water bottles, and basic medicines ready.\n• Store emergency contact numbers: ambulance (108), hospital (102), police (112).\n• Have a family plan to transport vulnerable members quickly.',
        gradient: [Color(0xFFFB7185), Color(0xFFF43F5E)],
        icon: Icons.assignment_turned_in_outlined,
      ),
    ];
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({required this.content});

  final _LearnContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: content.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: content.gradient.first.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(content.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              content.description,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnContent {
  const _LearnContent({
    required this.title,
    required this.description,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String description;
  final List<Color> gradient;
  final IconData icon;
}

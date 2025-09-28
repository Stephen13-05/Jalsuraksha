import 'package:flutter/material.dart';
import 'package:app/locale/locale_controller.dart';

enum VillagerNavTab { home, reportIssues, alerts, learn }

typedef VillagerNavSelect = void Function(VillagerNavTab tab);

class VillagerEmergencyContact {
  const VillagerEmergencyContact({
    required this.label,
    required this.number,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String number;
  final IconData icon;
  final List<Color> gradient;
}

class VillagerNavDrawer extends StatelessWidget {
  const VillagerNavDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.onOpenProfile,
    required this.onLogout,
    required this.contacts,
    required this.onCloseDrawer,
  });

  final VillagerNavTab currentTab;
  final VillagerNavSelect onSelectTab;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;
  final List<VillagerEmergencyContact> contacts;
  final VoidCallback onCloseDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: currentTab == VillagerNavTab.home,
              onTap: () {
                onCloseDrawer();
                onSelectTab(VillagerNavTab.home);
              },
            ),
            _DrawerItem(
              icon: Icons.report_problem_outlined,
              label: 'Sanitation Issues',
              selected: currentTab == VillagerNavTab.reportIssues,
              onTap: () {
                onCloseDrawer();
                onSelectTab(VillagerNavTab.reportIssues);
              },
            ),
            _DrawerItem(
              icon: Icons.notifications_active_outlined,
              label: 'Alerts & Notifications',
              selected: currentTab == VillagerNavTab.alerts,
              onTap: () {
                onCloseDrawer();
                onSelectTab(VillagerNavTab.alerts);
              },
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: 'Learn & Awareness',
              selected: currentTab == VillagerNavTab.learn,
              onTap: () {
                onCloseDrawer();
                onSelectTab(VillagerNavTab.learn);
              },
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Utilities',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                onCloseDrawer();
                onOpenProfile();
              },
            ),
            _DrawerItem(
              icon: Icons.language,
              label: 'Change language',
              onTap: () {
                onCloseDrawer();
                _showLanguagePicker(context);
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Emergency Contacts',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            _EmergencyContactList(contacts: contacts),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  onCloseDrawer();
                  onLogout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Villager Hub',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Monitor water safety, report issues, and stay informed',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    const languages = [
      ['en', 'English'],
      ['hi', 'हिन्दी'],
      ['ne', 'नेपाली'],
      ['as', 'অসমীয়া'],
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Choose language',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            ...languages.map((lang) => ListTile(
                  leading: const Icon(Icons.translate_outlined),
                  title: Text(lang[1]),
                  onTap: () => Navigator.pop(ctx, lang[0]),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      LocaleController.instance.setLocale(Locale(selected));
    }
  }
}

class _EmergencyContactList extends StatelessWidget {
  const _EmergencyContactList({required this.contacts});

  final List<VillagerEmergencyContact> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Emergency contacts will appear here once configured.',
            style: TextStyle(color: Color(0xFF475569)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _EmergencyContactCard(contact: contact);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemCount: contacts.length,
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact});

  final VillagerEmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: contact.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: contact.gradient.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(contact.icon, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            contact.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? theme.colorScheme.primary : const Color(0xFF64748B),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : const Color(0xFF111827),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: selected ? theme.colorScheme.primary.withOpacity(0.12) : null,
        onTap: onTap,
      ),
    );
  }
}

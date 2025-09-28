import 'package:flutter/material.dart';
import 'package:app/locale/locale_controller.dart';

enum AshaNavTab { home, dataCollection, reports, profile }

typedef AshaNavSelect = void Function(AshaNavTab tab);

class AshaNavDrawer extends StatelessWidget {
  final AshaNavTab currentTab;
  final AshaNavSelect onSelectTab;
  final VoidCallback onBluetoothSync;
  final VoidCallback onOfflineSync;
  final VoidCallback onChangeLanguage;

  const AshaNavDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.onBluetoothSync,
    required this.onOfflineSync,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Navigation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jump quickly between tools and utilities',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: currentTab == AshaNavTab.home,
              onTap: () {
                Navigator.of(context).pop();
                onSelectTab(AshaNavTab.home);
              },
            ),
            _DrawerItem(
              icon: Icons.fact_check_outlined,
              label: 'Data Collection',
              selected: currentTab == AshaNavTab.dataCollection,
              onTap: () {
                Navigator.of(context).pop();
                onSelectTab(AshaNavTab.dataCollection);
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Reports',
              selected: currentTab == AshaNavTab.reports,
              onTap: () {
                Navigator.of(context).pop();
                onSelectTab(AshaNavTab.reports);
              },
            ),
            _DrawerItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: currentTab == AshaNavTab.profile,
              onTap: () {
                Navigator.of(context).pop();
                onSelectTab(AshaNavTab.profile);
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
              icon: Icons.translate_rounded,
              label: 'Change language',
              onTap: () {
                Navigator.of(context).pop();
                onChangeLanguage();
              },
            ),
            _DrawerItem(
              icon: Icons.bluetooth_connected,
              label: 'Bluetooth sync',
              onTap: () {
                Navigator.of(context).pop();
                onBluetoothSync();
              },
            ),
            _DrawerItem(
              icon: Icons.cloud_sync,
              label: 'Offline sync',
              onTap: () {
                Navigator.of(context).pop();
                onOfflineSync();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Powered by Jal Suraksha',
                style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLanguagePicker(BuildContext context) async {
  const List<List<String>> options = [
    ['ne', 'नेपाली'],
    ['en', 'English'],
    ['as', 'অসমীয়া'],
    ['hi', 'हिन्दी'],
  ];

  final selected = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Choose language',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...options.map((opt) {
            final code = opt[0];
            final label = opt[1];
            return ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, code),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  if (selected != null && selected.isNotEmpty) {
    LocaleController.instance.setLocale(Locale(selected));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : const Color(0xFF6B7280),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? theme.colorScheme.primary : const Color(0xFF111827),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
        onTap: onTap,
      ),
    );
  }
}

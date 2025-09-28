import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/frontend/villagers/navigation.dart';
import 'package:app/frontend/villagers/home.dart';
import 'package:app/frontend/villagers/report_issue.dart';
import 'package:app/frontend/villagers/alerts.dart';
import 'package:app/frontend/villagers/learn.dart';
import 'package:app/frontend/villagers/profile.dart';
import 'package:app/frontend/villagers/login.dart';

class VillagerDashboardPage extends StatefulWidget {
  const VillagerDashboardPage({
    super.key,
    required this.uid,
    required this.fullName,
    required this.village,
    required this.district,
    this.state,
  });

  final String uid;
  final String fullName;
  final String village;
  final String district;
  final String? state;

  @override
  State<VillagerDashboardPage> createState() => _VillagerDashboardPageState();
}

class _VillagerDashboardPageState extends State<VillagerDashboardPage> {
  VillagerNavTab _currentTab = VillagerNavTab.home;

  late final List<VillagerEmergencyContact> _contacts;

  @override
  void initState() {
    super.initState();
    _contacts = [
      const VillagerEmergencyContact(
        label: 'Ambulance',
        number: '108',
        icon: Icons.local_hospital,
        gradient: [Color(0xFFF87171), Color(0xFFDC2626)],
      ),
      const VillagerEmergencyContact(
        label: 'Hospital',
        number: '102',
        icon: Icons.medical_information,
        gradient: [Color(0xFF60A5FA), Color(0xFF2563EB)],
      ),
      const VillagerEmergencyContact(
        label: 'Water Dept',
        number: '1916',
        icon: Icons.water_drop,
        gradient: [Color(0xFF34D399), Color(0xFF059669)],
      ),
      const VillagerEmergencyContact(
        label: 'Police SOS',
        number: '112',
        icon: Icons.shield,
        gradient: [Color(0xFFFBBF24), Color(0xFFCA8A04)],
      ),
    ];
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentTab = VillagerNavTab.values[index];
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('villager_uid');
    await prefs.remove('villager_name');
    await prefs.remove('villager_village');
    await prefs.remove('villager_district');
    await prefs.remove('villager_state');
    await prefs.remove('villager_phone');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VillagerLoginPage()),
      (route) => false,
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VillagerProfilePage(
          fullName: widget.fullName,
          village: widget.village,
          district: widget.district,
          state: widget.state,
          uid: widget.uid,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case VillagerNavTab.home:
        return VillagerHomeTab(
          uid: widget.uid,
          fullName: widget.fullName,
          village: widget.village,
          district: widget.district,
        );
      case VillagerNavTab.reportIssues:
        return VillagerReportIssueTab(
          uid: widget.uid,
          village: widget.village,
          district: widget.district,
        );
      case VillagerNavTab.alerts:
        return VillagerAlertsTab(
          village: widget.village,
          district: widget.district,
        );
      case VillagerNavTab.learn:
        return const VillagerLearnTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text(
          _currentTab == VillagerNavTab.home
              ? 'Welcome, ${widget.fullName.split(' ').first}'
              : _currentTab == VillagerNavTab.reportIssues
                  ? 'Report Sanitation Issues'
                  : _currentTab == VillagerNavTab.alerts
                      ? 'Alerts & Notifications'
                      : 'Learn & Awareness',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      drawer: VillagerNavDrawer(
        currentTab: _currentTab,
        onSelectTab: (tab) {
          setState(() => _currentTab = tab);
        },
        onOpenProfile: _openProfile,
        onLogout: () => _handleLogout(context),
        contacts: _contacts,
        onCloseDrawer: () => Navigator.of(context).pop(),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
    );
  }
}

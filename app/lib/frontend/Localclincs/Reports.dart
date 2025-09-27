import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

class ClinicReportsPage extends StatefulWidget {
  const ClinicReportsPage({super.key});

  @override
  State<ClinicReportsPage> createState() => _ClinicReportsPageState();
}

class _ClinicReportsPageState extends State<ClinicReportsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_ReportItem> _reports = [
    _ReportItem(
      patientId: '12345',
      collectedOn: DateTime(2024, 7, 26),
      source: 'Well',
      status: ReportStatus.safe,
    ),
    _ReportItem(
      patientId: '67890',
      collectedOn: DateTime(2024, 7, 25),
      source: 'Tap',
      status: ReportStatus.unsafe,
    ),
    _ReportItem(
      patientId: '11223',
      collectedOn: DateTime(2024, 7, 24),
      source: 'River',
      status: ReportStatus.pending,
    ),
  ];

  String _searchQuery = '';
  String _selectedSource = 'All';
  String _selectedStatus = 'all';
  String _selectedDateSort = 'newest';

  List<_ReportItem> get _filteredReports {
    List<_ReportItem> list = List.of(_reports);

    // Search by patient ID
    if (_searchQuery.trim().isNotEmpty) {
      list = list
          .where((r) => r.patientId.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by source
    if (_selectedSource != 'All') {
      list = list.where((r) => r.source == _selectedSource).toList();
    }

    // Filter by status (compare using status keys, not localized labels)
    if (_selectedStatus != 'all') {
      list = list.where((r) => _statusKey(r.status) == _selectedStatus).toList();
    }

    // Sort by date
    list.sort((a, b) => a.collectedOn.compareTo(b.collectedOn));
    if (_selectedDateSort == 'newest') {
      list = list.reversed.toList();
    }

    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  // Keep localization instance available for translations
  final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.t('nav_reports'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.t('add_new_report'))),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredReports.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _filteredReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final report = _filteredReports[index];
                          return _buildReportCard(report);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI builders
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
          child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).t('search_patient_id'),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
  final sources = const ['All', 'Well', 'Tap', 'River'];
  final statuses = const ['all', 'safe', 'unsafe', 'pending'];
  final dates = const ['newest', 'oldest'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _boxedDropdown<String>(
          value: _selectedSource,
          items: sources,
          onChanged: (val) => setState(() => _selectedSource = val ?? 'All'),
          labelBuilder: (v) => AppLocalizations.of(context).t('source_label'),
        ),
        _boxedDropdown<String>(
          value: _selectedStatus,
          items: statuses,
          onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
          labelBuilder: (v) => AppLocalizations.of(context).t('status_label'),
        ),
        _boxedDropdown<String>(
          value: _selectedDateSort,
          items: dates,
          onChanged: (val) => setState(() => _selectedDateSort = val ?? 'Newest first'),
          labelBuilder: (v) => AppLocalizations.of(context).t('date_label'),
        ),
      ],
    );
  }

  Widget _buildReportCard(_ReportItem r) {
  final String dateStr = r.collectedOn.toIso8601String().split('T').first;
  return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).t('patient_id_label')}: ${r.patientId}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppLocalizations.of(context).t('date_collected')}: $dateStr',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // localize known sources
                      () {
                        if (r.source == 'Well') return AppLocalizations.of(context).t('dc_source_well');
                        if (r.source == 'Tap') return AppLocalizations.of(context).t('dc_source_tap');
                        if (r.source == 'River') return AppLocalizations.of(context).t('dc_source_river_pond');
                        return r.source;
                      }(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // larger, centered status dot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(child: _statusDot(r.status)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallOutlinedButton(AppLocalizations.of(context).t('view_details'), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).t('viewing_details') + ' ${r.patientId}')),
                );
              }),
              _smallOutlinedButton(AppLocalizations.of(context).t('edit'), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).t('edit_item') + ' ${r.patientId}')),
                );
              }),
              _smallOutlinedButton(AppLocalizations.of(context).t('delete'), () {
                _confirmDelete(r);
              }, color: const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  // Widgets and helpers
  Widget _boxedDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: false,
          icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                        child: Text(
                          // Localize display for known keys
                          () {
                            final s = e.toString();
                            if (s == 'All' || s == 'all') return AppLocalizations.of(context).t('all');
                            if (s == 'Well') return AppLocalizations.of(context).t('dc_source_well');
                            if (s == 'Tap') return AppLocalizations.of(context).t('dc_source_tap');
                            if (s == 'River') return AppLocalizations.of(context).t('dc_source_river_pond');
                            // status keys
                            if (s == 'safe') return AppLocalizations.of(context).t('status_safe');
                            if (s == 'unsafe') return AppLocalizations.of(context).t('status_unsafe');
                            if (s == 'pending') return AppLocalizations.of(context).t('status_pending');
                            if (s == 'newest') return AppLocalizations.of(context).t('sort_newest_first');
                            if (s == 'oldest') return AppLocalizations.of(context).t('sort_oldest_first');
                            return s;
                          }(),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                  ))
              .toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) => items
              .map((e) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // Show localized label for the selected value
                      () {
                        final s = e.toString();
                        if (s == 'All' || s == 'all') return AppLocalizations.of(context).t('all');
                        if (s == 'Well') return AppLocalizations.of(context).t('dc_source_well');
                        if (s == 'Tap') return AppLocalizations.of(context).t('dc_source_tap');
                        if (s == 'River') return AppLocalizations.of(context).t('dc_source_river_pond');
                        if (s == 'safe') return AppLocalizations.of(context).t('status_safe');
                        if (s == 'unsafe') return AppLocalizations.of(context).t('status_unsafe');
                        if (s == 'pending') return AppLocalizations.of(context).t('status_pending');
                        if (s == 'newest') return AppLocalizations.of(context).t('sort_newest_first');
                        if (s == 'oldest') return AppLocalizations.of(context).t('sort_oldest_first');
                        return s;
                      }(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  String _statusKey(ReportStatus s) {
    switch (s) {
      case ReportStatus.safe:
        return 'safe';
      case ReportStatus.unsafe:
        return 'unsafe';
      case ReportStatus.pending:
        return 'pending';
    }
  }

  Widget _smallOutlinedButton(String label, VoidCallback onPressed, {Color? color}) {
    final c = color ?? const Color(0xFF334155);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: const Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusDot(ReportStatus status) {
    final Color color;
    switch (status) {
      case ReportStatus.safe:
        color = const Color(0xFF16A34A); // green
        break;
      case ReportStatus.unsafe:
        color = const Color(0xFFEF4444); // red
        break;
      case ReportStatus.pending:
        color = const Color(0xFF3B82F6); // blue
        break;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildEmptyState() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(loc.t('no_reports_found'), style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(_ReportItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('delete_report_confirm')),
        content: Text('${AppLocalizations.of(context).t('delete_report_confirmation')} ${r.patientId}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context).t('delete'))),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _reports.remove(r));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('report_deleted'))),
        );
      }
    }
  }

  // status label is now handled via localization keys; use _statusKey when needed
}

enum ReportStatus { safe, unsafe, pending }

class _ReportItem {
  final String patientId;
  final DateTime collectedOn;
  final String source;
  final ReportStatus status;

  _ReportItem({
    required this.patientId,
    required this.collectedOn,
    required this.source,
    required this.status,
  });
}


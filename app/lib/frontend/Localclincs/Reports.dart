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
      status: ReportStatus.completed,
    ),
    _ReportItem(
      patientId: '67890',
      collectedOn: DateTime(2024, 7, 25),
      source: 'Tap',
      status: ReportStatus.completed,
    ),
    _ReportItem(
      patientId: '11223',
      collectedOn: DateTime(2024, 7, 24),
      source: 'River',
      status: ReportStatus.completed,
    ),
  ];

  String _searchQuery = '';
  String _selectedSource = 'All';
  String _selectedStatus = 'All';
  String _selectedDateSort = 'Newest first';

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

    // Filter by status
    if (_selectedStatus != 'All') {
      list = list.where((r) => _statusLabel(r.status) == _selectedStatus).toList();
    }

    // Sort by date
    list.sort((a, b) => a.collectedOn.compareTo(b.collectedOn));
    if (_selectedDateSort == 'Newest first') {
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
    // Keep localization instance available for future key-based translations
    final _ = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
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
            const SnackBar(content: Text('Add new report')),
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
        decoration: const InputDecoration(
          hintText: 'Search  Patient ID',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final sources = const ['All', 'Well', 'Tap', 'River'];
    final statuses = const ['All', 'Completed', 'Pending', 'In Progress'];
    final dates = const ['Newest first', 'Oldest first'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _boxedDropdown<String>(
          value: _selectedSource,
          items: sources,
          onChanged: (val) => setState(() => _selectedSource = val ?? 'All'),
          labelBuilder: (v) => 'Source',
        ),
        _boxedDropdown<String>(
          value: _selectedStatus,
          items: statuses,
          onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
          labelBuilder: (v) => 'Status',
        ),
        _boxedDropdown<String>(
          value: _selectedDateSort,
          items: dates,
          onChanged: (val) => setState(() => _selectedDateSort = val ?? 'Newest first'),
          labelBuilder: (v) => 'Date',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient ID: ${r.patientId}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Date Collected: $dateStr',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.source,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: _statusDot(r.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallOutlinedButton('View Details', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing details for ${r.patientId}')),
                );
              }),
              _smallOutlinedButton('Edit', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit ${r.patientId}')),
                );
              }),
              _smallOutlinedButton('Delete', () {
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
                      e.toString(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) => items
              .map((e) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      labelBuilder(e),
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
      case ReportStatus.completed:
        color = const Color(0xFF16A34A); // green
        break;
      case ReportStatus.pending:
        color = const Color(0xFFF59E0B); // amber
        break;
      case ReportStatus.inProgress:
        color = const Color(0xFF3B82F6); // blue
        break;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text('No reports found', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(_ReportItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('This will remove the report for Patient ID ${r.patientId}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _reports.remove(r));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted')),
        );
      }
    }
  }

  String _statusLabel(ReportStatus s) {
    switch (s) {
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
    }
  }
}

enum ReportStatus { completed, pending, inProgress }

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


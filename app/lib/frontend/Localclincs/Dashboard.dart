import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

class ClinicDashboard extends StatefulWidget {
  const ClinicDashboard({super.key});

  @override
  State<ClinicDashboard> createState() => _ClinicDashboardState();
}

class _ClinicDashboardState extends State<ClinicDashboard> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            // TODO: Open drawer
          },
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.black87),
            onPressed: () {
              // TODO: Language selector
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Summary Section
            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildSummaryCard(
                  title: 'Patients\nReported',
                  value: '23',
                  backgroundColor: Colors.white,
                ),
                _buildSummaryCard(
                  title: 'Water-borne\nCases',
                  value: '8',
                  backgroundColor: Colors.white,
                ),
                _buildSummaryCard(
                  title: 'Water Samples\nSent',
                  value: '15',
                  backgroundColor: Colors.white,
                ),
                _buildSummaryCard(
                  title: 'Pending\nReports',
                  value: '3',
                  backgroundColor: Colors.white,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Assigned Villages Section
            const Text(
              'Assigned Villages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Map Container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Map View\n(Villages Assignment)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomNavItem(
                  icon: Icons.add_circle_outline,
                  label: 'Add Patient\nCase',
                  onTap: () {
                    // TODO: Navigate to Add Patient Case
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.upload_file_outlined,
                  label: 'Upload Test\nResult',
                  onTap: () {
                    // TODO: Navigate to Upload Test Result
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.report_outlined,
                  label: 'Report\nOutbreak',
                  onTap: () {
                    // TODO: Navigate to Report Outbreak
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.request_page_outlined,
                  label: 'Resource\nRequests',
                  onTap: () {
                    // TODO: Navigate to Resource Requests
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

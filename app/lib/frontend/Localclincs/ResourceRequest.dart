import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/locale/locale_controller.dart';

class ResourceRequestPage extends StatefulWidget {
  const ResourceRequestPage({super.key});

  @override
  State<ResourceRequestPage> createState() => _ResourceRequestPageState();
}

class _ResourceRequestPageState extends State<ResourceRequestPage> {
  // Medicine shortage selections
  bool _orsSelected = false;
  bool _ivFluidsSelected = false;
  bool _antibioticsSelected = false;
  bool _othersSelected = false;

  // Staff shortage selections
  bool _doctorsSelected = false;
  bool _nursesSelected = false;
  bool _healthAssistantsSelected = false;

  // Referral requests selections
  bool _districtHospitalSelected = false;
  bool _ngoSupportSelected = false;
  bool _testingLabSelected = false;

  bool _isSubmitting = false;

  String _getLocalizedText(BuildContext context, String key, String fallback) {
    try {
      final localizations = AppLocalizations.of(context);
      return localizations.t(key);
    } catch (e) {
      return fallback;
    }
  }

  Future<void> _submitRequest() async {
    // Check if at least one item is selected
    bool hasSelection = _orsSelected || _ivFluidsSelected || _antibioticsSelected || _othersSelected ||
                       _doctorsSelected || _nursesSelected || _healthAssistantsSelected ||
                       _districtHospitalSelected || _ngoSupportSelected || _testingLabSelected;

    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedText(context, 'select_at_least_one', 'Please select at least one resource or request')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // TODO: Implement submit request logic
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getLocalizedText(context, 'request_submitted_success', 'Resource request submitted successfully!')),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to dashboard
    Navigator.pop(context);
  }

  void _trackRequests() {
    // TODO: Implement track requests functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getLocalizedText(context, 'track_requests_info', 'Track requests feature coming soon!')),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B82F6),
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(_getLocalizedText(context, 'resources_references', 'Resources & References')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.public, size: 20, color: Colors.black54),
            onSelected: (code) {
              // Apply language change globally
              switch (code) {
                case 'ne':
                case 'en':
                case 'as':
                case 'hi':
                  LocaleController.instance.setLocale(Locale(code));
                  // Force rebuild to apply changes immediately
                  setState(() {});
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ne', child: Text('Nepali')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'as', child: Text('Assamese')),
              PopupMenuItem(value: 'hi', child: Text('Hindi')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicines Shortage Section
                      _buildSectionHeader(_getLocalizedText(context, 'medicines_shortage', 'Medicines Shortage')),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'ors', 'ORS'),
                        value: _orsSelected,
                        onChanged: (value) => setState(() => _orsSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'iv_fluids', 'IV Fluids'),
                        value: _ivFluidsSelected,
                        onChanged: (value) => setState(() => _ivFluidsSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'antibiotics', 'Antibiotics'),
                        value: _antibioticsSelected,
                        onChanged: (value) => setState(() => _antibioticsSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'others', 'Others'),
                        value: _othersSelected,
                        onChanged: (value) => setState(() => _othersSelected = value ?? false),
                      ),

                      // Staff Shortage Section
                      _buildSectionHeader(_getLocalizedText(context, 'staff_shortage', 'Staff Shortage')),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'doctors', 'Doctors'),
                        value: _doctorsSelected,
                        onChanged: (value) => setState(() => _doctorsSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'nurses', 'Nurses'),
                        value: _nursesSelected,
                        onChanged: (value) => setState(() => _nursesSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'health_assistants', 'Health Assistants'),
                        value: _healthAssistantsSelected,
                        onChanged: (value) => setState(() => _healthAssistantsSelected = value ?? false),
                      ),

                      // Referral Requests Section
                      _buildSectionHeader(_getLocalizedText(context, 'referral_requests', 'Referral Requests')),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'district_hospital', 'District Hospital'),
                        value: _districtHospitalSelected,
                        onChanged: (value) => setState(() => _districtHospitalSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'ngo_support', 'NGO Support'),
                        value: _ngoSupportSelected,
                        onChanged: (value) => setState(() => _ngoSupportSelected = value ?? false),
                      ),
                      
                      _buildCheckboxItem(
                        title: _getLocalizedText(context, 'testing_lab', 'Testing Lab'),
                        value: _testingLabSelected,
                        onChanged: (value) => setState(() => _testingLabSelected = value ?? false),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _getLocalizedText(context, 'submit_request', 'Submit Request'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _trackRequests,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6B7280)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _getLocalizedText(context, 'track_requests', 'Track Requests'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

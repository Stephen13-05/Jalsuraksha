import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:file_picker/file_picker.dart';

class ReportOutbreakPage extends StatefulWidget {
  const ReportOutbreakPage({super.key});

  @override
  State<ReportOutbreakPage> createState() => _ReportOutbreakPageState();
}

class _ReportOutbreakPageState extends State<ReportOutbreakPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _suspectedCasesController = TextEditingController();
  final _locationController = TextEditingController();
  final _riskFactorsController = TextEditingController();
  
  // Dropdown values
  String? _selectedOutbreak;
  String? _selectedRiskFactor;
  DateTime? _firstCaseDate;
  
  // File upload
  String? _uploadedFileName;
  
  bool _isFlagging = false;
  bool _isNotifying = false;

  final List<String> _outbreakTypes = [
    'cholera',
    'dysentery', 
    'typhoid',
    'hepatitis_a',
    'other'
  ];

  final List<String> _riskFactorOptions = [
    'flooding',
    'contaminated_source',
    'poor_sanitation'
  ];

  @override
  void dispose() {
    _suspectedCasesController.dispose();
    _locationController.dispose();
    _riskFactorsController.dispose();
    super.dispose();
  }

  String _getLocalizedText(BuildContext context, String key, String fallback) {
    try {
      final localizations = AppLocalizations.of(context);
      return localizations.t(key);
    } catch (e) {
      return fallback;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstCaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _firstCaseDate) {
      setState(() {
        _firstCaseDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'doc', 'docx'],
        withData: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploadedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText(context, 'file_upload_error', 'Error uploading file'))),
      );
    }
  }

  Future<void> _flagOutbreak() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText(context, 'form_fix_errors', 'Please fix the errors in the form'))),
      );
      return;
    }

    setState(() => _isFlagging = true);
    
    // TODO: Implement flag outbreak logic
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isFlagging = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getLocalizedText(context, 'outbreak_flagged_success', 'Outbreak flagged successfully!')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _notifyDistrictHealthOfficer() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText(context, 'form_fix_errors', 'Please fix the errors in the form'))),
      );
      return;
    }

    setState(() => _isNotifying = true);
    
    // TODO: Implement notify district health officer logic
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isNotifying = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getLocalizedText(context, 'district_officer_notified', 'District Health Officer notified successfully!')),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to dashboard
    Navigator.pop(context);
  }

  // Match visual style with other local clinic pages
  InputDecoration _filledDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: InputBorder.none,
    );
  }

  Widget _boxedField({required Widget child, double height = 56}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemDisplayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
              ),
              icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(
                          itemDisplayText(e),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(_getLocalizedText(context, 'report_outbreak_cluster', 'Report Outbreak Cluster')),
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Suspected Outbreak
                        _dropdownField<String>(
                          label: _getLocalizedText(context, 'suspected_outbreak', 'Suspected Outbreak'),
                          value: _selectedOutbreak,
                          items: _outbreakTypes,
                          onChanged: (val) => setState(() => _selectedOutbreak = val),
                          itemDisplayText: (item) => _getLocalizedText(context, 'outbreak_$item', item.replaceAll('_', ' ').toUpperCase()),
                        ),
                        const SizedBox(height: 16),

                        // No. of Suspected Cases
                        Text(
                          _getLocalizedText(context, 'no_suspected_cases', 'No. of Suspected Cases'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _boxedField(
                          child: TextFormField(
                            controller: _suspectedCasesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: _getLocalizedText(context, 'enter_number_cases', 'Enter number of cases'),
                              prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? _getLocalizedText(context, 'field_required', 'This field is required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location/Village Affected
                        Text(
                          _getLocalizedText(context, 'location_village_affected', 'Location/Village Affected'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _boxedField(
                          child: TextFormField(
                            controller: _locationController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: _getLocalizedText(context, 'enter_location', 'Enter location or village name'),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? _getLocalizedText(context, 'field_required', 'This field is required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // First Case Date
                        Text(
                          _getLocalizedText(context, 'first_case_date', 'First Case Date'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Color(0xFF9CA3AF), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _firstCaseDate != null
                                        ? '${_firstCaseDate!.day}/${_firstCaseDate!.month}/${_firstCaseDate!.year}'
                                        : _getLocalizedText(context, 'select_date', 'Select Date'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _firstCaseDate != null ? Colors.black87 : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Observed Risk Factors
                        Text(
                          _getLocalizedText(context, 'observed_risk_factors', 'Observed Risk Factors'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 120,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextFormField(
                            controller: _riskFactorsController,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: _getLocalizedText(context, 'describe_risk_factors', 'Describe observed risk factors (flooding, contaminated source, poor sanitation)'),
                              prefixIcon: const Icon(Icons.warning_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? _getLocalizedText(context, 'field_required', 'This field is required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Upload Supporting Files
                        Text(
                          _getLocalizedText(context, 'upload_supporting_files', 'Upload Supporting Files'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                            ),
                            height: 80,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(Icons.upload_file_outlined, color: Color(0xFF64748B), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _uploadedFileName ?? _getLocalizedText(context, 'upload_files_hint', 'Click to upload images or reports'),
                                    style: TextStyle(
                                      color: _uploadedFileName != null ? Colors.black87 : const Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.add, color: Color(0xFF64748B), size: 24),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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
                      onPressed: _isFlagging ? null : _flagOutbreak,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isFlagging
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _getLocalizedText(context, 'flag_outbreak', 'Flag Outbreak'),
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
                      onPressed: _isNotifying ? null : _notifyDistrictHealthOfficer,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6B7280)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isNotifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF6B7280),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _getLocalizedText(context, 'notify_district_health_officer', 'Notify District Health Officer'),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/locale/locale_controller.dart';

class AddPatientCasePage extends StatefulWidget {
  const AddPatientCasePage({super.key});

  @override
  State<AddPatientCasePage> createState() => _AddPatientCasePageState();
}

class _AddPatientCasePageState extends State<AddPatientCasePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _diseasePredictedController = TextEditingController();
  final _villageWardController = TextEditingController();
  final _treatmentController = TextEditingController();
  
  // Dropdown values
  String? _selectedGender;
  String? _selectedSymptoms;
  DateTime? _selectedDate;
  
  bool _isSaving = false;
  bool _isSubmitting = false;

  // Option lists use localization keys (displayed via localizations.t(key))
  final List<String> _genderOptions = ['gender_male', 'gender_female', 'gender_other'];
  final List<String> _symptomsOptions = [
    'fever',
    'diarrhea',
    'vomiting',
    'abdominal_pain',
    'dehydration',
    'nausea',
    'headache',
    'fatigue'
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _diseasePredictedController.dispose();
    _villageWardController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('form_fix_errors'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    // TODO: Implement save case logic
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    setState(() => _isSaving = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('case_saved')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('form_fix_errors'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // TODO: Implement submit report logic
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('report_submitted')),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  // helper removed: use AppLocalizations.of(context).t('key') directly

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
    
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
  title: Text(AppLocalizations.of(context).t('add_patient_case')),
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
                        // Patient Name/ID
                          Text(
                            AppLocalizations.of(context).t('patient_id_label'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _boxedField(
                          child: TextFormField(
                            controller: _patientNameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                                hint: AppLocalizations.of(context).t('enter_patient_id'),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).t('field_required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Age and Gender Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).t('age'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _boxedField(
                                    child: TextFormField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(fontSize: 16),
                                      decoration: _filledDecoration(
                                        hint: AppLocalizations.of(context).t('enter_age'),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).t('field_required') : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdownField<String>(
                                label: AppLocalizations.of(context).t('gender'),
                                value: _selectedGender,
                                items: _genderOptions,
                                onChanged: (val) => setState(() => _selectedGender = val),
                                // Display without the 'gender_' prefix (keep stored value intact)
                                itemDisplayText: (item) => AppLocalizations.of(context).t(item.replaceFirst('gender_', '')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Symptoms
                        _dropdownField<String>(
                          label: AppLocalizations.of(context).t('symptoms_hint'),
                          value: _selectedSymptoms,
                          items: _symptomsOptions,
                          onChanged: (val) => setState(() => _selectedSymptoms = val),
                          itemDisplayText: (item) => AppLocalizations.of(context).t(item),
                        ),
                        const SizedBox(height: 16),

                        // Disease Predicted
                        Text(
                          AppLocalizations.of(context).t('disease_predicted'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _boxedField(
                          child: TextFormField(
                            controller: _diseasePredictedController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('disease_name'),
                              prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).t('field_required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date of Onset
                        Text(
                          AppLocalizations.of(context).t('date_of_onset'),
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
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : AppLocalizations.of(context).t('select_date'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate != null ? Colors.black87 : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Village/Ward
                        Text(
                          AppLocalizations.of(context).t('village_ward'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _boxedField(
                          child: TextFormField(
                            controller: _villageWardController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('enter_village_ward'),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).t('field_required') : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Treatment Given
                        Text(
                          AppLocalizations.of(context).t('treatment_given'),
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
                            controller: _treatmentController,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('enter_treatment_details'),
                              prefixIcon: const Icon(Icons.healing_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).t('field_required') : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _saveCase,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3B82F6),
                                  strokeWidth: 2,
                                ),
                              )
                                : Text(
                                AppLocalizations.of(context).t('save_case'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
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
                                AppLocalizations.of(context).t('submit_report'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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

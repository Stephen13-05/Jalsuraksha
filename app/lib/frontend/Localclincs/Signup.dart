import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/frontend/Localclincs/Login.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';


class ClinicSignUpPage extends StatefulWidget {
  const ClinicSignUpPage({super.key});

  @override
  State<ClinicSignUpPage> createState() => _ClinicSignUpPageState();
}

class _ClinicSignUpPageState extends State<ClinicSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Clinic information controllers
  final _clinicNameController = TextEditingController();
  final _clinicIdController = TextEditingController();
  String? _selectedClinicType;
  final List<String> _clinicTypes = const [
    // Values are placeholders; display text will be localized during build
    'phc',
    'chc',
    'private',
    'ngo',
    'other',
  ];
  final _districtVillageController = TextEditingController();
  final _addressPinController = TextEditingController();

  // Staff information controllers
  final _staffNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _mobileController = TextEditingController();

  // Verification docs (mock placeholders)
  String? _clinicRegDocPath;
  String? _doctorIdDocPath;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicIdController.dispose();
    _districtVillageController.dispose();
    _addressPinController.dispose();
    _staffNameController.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) => RegExp(r'^[0-9]{10}$').hasMatch(input);

  Future<String?> _pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    return file.name; // Display-only; integration can use path if needed: file.path
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('form_fix_errors'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    // TODO: Integrate with backend service for clinic registration.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration submitted!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  // Match visual style with ASHA pages: filled grey boxes, rounded corners
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
              icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(
                          e.toString(),
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

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _uploadBox({
    required String label,
    required VoidCallback onTap,
    String? fileName,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text(
                    fileName ?? 'Click to upload',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  const Text('SVG, PNG, JPG or GIF', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    // Build localized display map for clinic types
    final Map<String, String> clinicTypeLabels = {
      'phc': t('clinic_type_phc'),
      'chc': t('clinic_type_chc'),
      'private': t('clinic_type_private'),
      'ngo': t('clinic_type_ngo'),
      'other': t('clinic_type_other'),
    };
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(t('clinic_register_title')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top header area with centered logo and language selector at top-right
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset('assets/images/logo.png', height: 140, fit: BoxFit.contain),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.public, size: 20, color: Colors.black54),
                        onSelected: (code) {
                          switch (code) {
                            case 'ne':
                            case 'en':
                            case 'as':
                            case 'hi':
                              LocaleController.instance.setLocale(Locale(code));
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(t('clinic_info_section')),
                        const SizedBox(height: 12),

                        // Clinic Name
                        _boxedField(
                          child: TextFormField(
                            controller: _clinicNameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('clinic_name_hint'),
                              prefixIcon: const Icon(Icons.local_hospital_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('name_empty') : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Clinic ID / Registration Number
                        _boxedField(
                          child: TextFormField(
                            controller: _clinicIdController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('clinic_id_hint'),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('id_empty') : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Clinic Type
                        _dropdownField<String>(
                          label: t('clinic_type_label'),
                          value: _selectedClinicType,
                          items: clinicTypeLabels.values.toList(),
                          onChanged: (val) => setState(() => _selectedClinicType = val),
                        ),
                        const SizedBox(height: 12),

                        // District / Village
                        _boxedField(
                          child: TextFormField(
                            controller: _districtVillageController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('district_village_hint'),
                              prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('dc_enter_district') : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Address & Pin Code
                        _boxedField(
                          height: 80,
                          child: TextFormField(
                            controller: _addressPinController,
                            maxLines: 2,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('address_pin_hint'),
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('dc_enter_address') : null,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionHeader(t('staff_info_section')),
                        const SizedBox(height: 12),

                        // Staff Name
                        _boxedField(
                          child: TextFormField(
                            controller: _staffNameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('name_hint'),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('name_empty') : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Designation
                        _boxedField(
                          child: TextFormField(
                            controller: _designationController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: t('designation_hint'),
                              prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('not_specified') : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mobile with Verify OTP button
                        _boxedField(
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: t('mobile_hint'),
                                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return t('mobile_required');
                                    if (!_isValidPhone(v)) return t('mobile_invalid');
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionHeader(t('verification_docs_section')),
                        const SizedBox(height: 12),

                        _uploadBox(
                          label: t('upload_clinic_doc'),
                          fileName: _clinicRegDocPath,
                          onTap: () async {
                            final picked = await _pickFile(allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif']);
                            if (picked != null) {
                              setState(() => _clinicRegDocPath = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        _uploadBox(
                          label: t('upload_doctor_id'),
                          fileName: _doctorIdDocPath,
                          onTap: () async {
                            final picked = await _pickFile(allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'pdf']);
                            if (picked != null) {
                              setState(() => _doctorIdDocPath = picked);
                            }
                          },
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
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
                                    t('register_clinic_button'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                t('already_have_account'),
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const ClinicLoginPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  t('login_cta'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/l10n/app_localizations.dart';

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
    'Primary Health Center',
    'Community Health Center',
    'Private Clinic',
    'NGO Clinic',
    'Other',
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

  bool _isVerifyingOtp = false;
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

  Future<void> _verifyOtp() async {
    if (!_isValidPhone(_mobileController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('phone_invalid'))),
      );
      return;
    }
    setState(() => _isVerifyingOtp = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isVerifyingOtp = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to mobile number')),
    );
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
                    fileName ?? 'Click to upload or drag and drop',
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Register Clinic'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language selector aligned to end (kept consistent with ASHA pages)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
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
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  height: 120,
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
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
                        _sectionHeader('Clinic Information'),
                        const SizedBox(height: 12),

                        // Clinic Name
                        _boxedField(
                          child: TextFormField(
                            controller: _clinicNameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: 'Enter clinic name',
                              prefixIcon: const Icon(Icons.local_hospital_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Clinic name is required' : null,
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
                              hint: 'Enter clinic ID',
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Clinic ID is required' : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Clinic Type
                        _dropdownField<String>(
                          label: 'Type',
                          value: _selectedClinicType,
                          items: _clinicTypes,
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
                              hint: 'Enter district or village',
                              prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'District/Village is required' : null,
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
                              hint: 'Enter address and pin code',
                              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address & Pin Code is required' : null,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionHeader('Staff Information'),
                        const SizedBox(height: 12),

                        // Staff Name
                        _boxedField(
                          child: TextFormField(
                            controller: _staffNameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: 'Enter name',
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
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
                              hint: 'Enter designation',
                              prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
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
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter mobile number',
                                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Mobile number is required';
                                    if (!_isValidPhone(v)) return 'Enter a valid 10-digit mobile number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _isVerifyingOtp ? null : _verifyOtp,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF22C55E),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isVerifyingOtp
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Verify OTP'),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionHeader('Verification Documents'),
                        const SizedBox(height: 12),

                        _uploadBox(
                          label: 'Upload Clinic Registration Certificate / ID Proof',
                          fileName: _clinicRegDocPath,
                          onTap: () {
                            // TODO: Integrate file picker
                            setState(() => _clinicRegDocPath = 'document_selected.pdf');
                          },
                        ),
                        const SizedBox(height: 12),

                        _uploadBox(
                          label: 'Upload Doctor ID (optional but recommended)',
                          fileName: _doctorIdDocPath,
                          onTap: () {
                            // TODO: Integrate file picker
                            setState(() => _doctorIdDocPath = 'doctor_id_image.jpg');
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
                                : const Text(
                                    'Register Clinic',
                                    style: TextStyle(
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
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
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


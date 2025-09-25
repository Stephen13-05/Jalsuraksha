import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/frontend/ashaworkers/login.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/services/asha_auth_service.dart';

class AshaWorkerSignUpPage extends StatefulWidget {
  const AshaWorkerSignUpPage({super.key});

  @override
  State<AshaWorkerSignUpPage> createState() => _AshaWorkerSignUpPageState();
}

class _AshaWorkerSignUpPageState extends State<AshaWorkerSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AshaAuthService _authService = AshaAuthService();

  // Region data (Northeast India focused)
  final List<String> _countries = const ['India'];
  final Map<String, List<String>> _statesByCountry = const {
    'India': [
      'Assam',
      'Arunachal Pradesh',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Tripura',
      'Sikkim',
    ],
  };

  final Map<String, List<String>> _districtsByState = const {
    'Assam': ['Kamrup Metropolitan', 'Nagaon', 'Dibrugarh', 'Tinsukia'],
    'Arunachal Pradesh': ['Papum Pare', 'East Siang', 'West Kameng'],
    'Manipur': ['Imphal West', 'Imphal East', 'Thoubal'],
    'Meghalaya': ['East Khasi Hills', 'West Garo Hills'],
    'Mizoram': ['Aizawl', 'Lunglei'],
    'Nagaland': ['Kohima', 'Dimapur'],
    'Tripura': ['West Tripura', 'South Tripura'],
    'Sikkim': ['East Sikkim', 'South Sikkim'],
  };

  final Map<String, List<String>> _villagesByDistrict = const {
    'Kamrup Metropolitan': ['Sonapur', 'Amingaon', 'Chandrapur'],
    'Nagaon': ['Doboka', 'Hojai', 'Rupahi'],
    'Dibrugarh': ['Chabua', 'Moran', 'Naharkatia'],
    'Tinsukia': ['Digboi', 'Margherita', 'Makum'],
    'Papum Pare': ['Itanagar', 'Doimukh'],
    'East Siang': ['Pasighat', 'Mebo'],
    'West Kameng': ['Bomdila', 'Rupa'],
    'Imphal West': ['Lamphel', 'Langjing'],
    'Imphal East': ['Porompat', 'Andro'],
    'Thoubal': ['Yairipok', 'Lamai'],
    'East Khasi Hills': ['Sohra', 'Mawphlang'],
    'West Garo Hills': ['Tura', 'Dalu'],
    'Aizawl': ['Selesih', 'Zarkawt'],
    'Lunglei': ['Serkawn', 'Chanmari'],
    'Kohima': ['Jotsoma', 'Sechu-Zubza'],
    'Dimapur': ['Chumukedima', 'Medziphema'],
    'West Tripura': ['Ranirbazar', 'Dukli'],
    'South Tripura': ['Belonia', 'Sabroom'],
    'East Sikkim': ['Rangpo', 'Majitar'],
    'South Sikkim': ['Namchi', 'Jorethang'],
  };

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) => RegExp(r'^[0-9]{10}$').hasMatch(input);

  bool _isValidPassword(String input) {
    // Exactly 10 chars; must include at least one uppercase and one special character
    if (input.length != 10) return false;
    final hasUpper = input.contains(RegExp(r'[A-Z]'));
    final hasSpecial = input.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    return hasUpper && hasSpecial;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('form_fix_errors'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Register user using the Firestore-backed ASHA auth service
      final result = await _authService.register(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        ashaId: _idController.text.trim(),
        country: _selectedCountry,
        state: _selectedState,
        district: _selectedDistrict,
        village: _selectedVillage,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.isSuccess) {
        // Mark as returning user for future launches
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isReturningUser', true);
        } catch (_) {}
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! You can now login.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // After successful signup, go to Login (works even if SignUp was the first page)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerLoginPage()),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
      // Borders/fill/colors will inherit from ThemeData.inputDecorationTheme
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
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
          height: 56, // match TextFormField visual height
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

  Widget _boxedField({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final states = _statesByCountry[_selectedCountry] ?? [];
    final districts = _selectedState != null ? (_districtsByState[_selectedState!] ?? []) : <String>[];
    final villages = _selectedDistrict != null ? (_villagesByDistrict[_selectedDistrict!] ?? []) : <String>[];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).t('title_signup')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language selector (same as login)
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
              // Static Logo at top
              const Center(
                child: SizedBox(
                  height: 150,
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable form below logo
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ASHA Worker ID
                        _boxedField(
                          child: TextFormField(
                            controller: _idController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('hint_asha_id'),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppLocalizations.of(context).t('id_empty')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Full Name
                        _boxedField(
                          child: TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('hint_full_name'),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppLocalizations.of(context).t('name_empty')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone Number
                        _boxedField(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('hint_phone'),
                              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).t('phone_empty');
                              }
                              if (!_isValidPhone(value)) {
                                return AppLocalizations.of(context).t('phone_invalid');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        _boxedField(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('hint_password'),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 22),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return AppLocalizations.of(context).t('password_empty');
                              if (!_isValidPassword(value)) {
                                return 'Password must be exactly 10 characters, include at least one uppercase letter and one special character';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Confirm Password
                        _boxedField(
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(fontSize: 16),
                            decoration: _filledDecoration(
                              hint: AppLocalizations.of(context).t('hint_confirm_password'),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return AppLocalizations.of(context).t('confirm_password_empty');
                              if (value != _passwordController.text) return AppLocalizations.of(context).t('password_mismatch');
                              if (!_isValidPassword(value)) return 'Password must be exactly 10 characters, include at least one uppercase letter and one special character';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                // Country
                _dropdownField<String>(
                  label: AppLocalizations.of(context).t('label_country'),
                  value: _selectedCountry,
                  items: _countries,
                  onChanged: (val) {
                    setState(() {
                      _selectedCountry = val;
                      _selectedState = null;
                      _selectedDistrict = null;
                      _selectedVillage = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // State
                _dropdownField<String>(
                  label: AppLocalizations.of(context).t('label_state'),
                  value: _selectedState,
                  items: states,
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedDistrict = null;
                      _selectedVillage = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // District
                _dropdownField<String>(
                  label: AppLocalizations.of(context).t('label_district'),
                  value: _selectedDistrict,
                  items: districts,
                  onChanged: (val) {
                    setState(() {
                      _selectedDistrict = val;
                      _selectedVillage = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Village (as dropdown for consistency)
                _dropdownField<String>(
                  label: AppLocalizations.of(context).t('label_village'),
                  value: _selectedVillage,
                  items: villages,
                  onChanged: (val) {
                    setState(() {
                      _selectedVillage = val;
                    });
                  },
                ),

                const SizedBox(height: 20),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context).t('sign_up'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Back to Login
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const AshaWorkerLoginPage()),
                                    ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppLocalizations.of(context).t('back_to_login'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/frontend/villagers/login.dart';
import 'package:app/services/villager_auth_service.dart';
import 'package:app/locale/locale_controller.dart';

class VillagerSignUpPage extends StatefulWidget {
  const VillagerSignUpPage({super.key});

  @override
  State<VillagerSignUpPage> createState() => _VillagerSignUpPageState();
}

class _VillagerSignUpPageState extends State<VillagerSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _auth = VillagerAuthService();
  final _genders = const ['Female', 'Male', 'Other'];

  final List<String> _states = const [
    'Assam',
    'Arunachal Pradesh',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Tripura',
    'Sikkim',
  ];

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

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedVillage;

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) => RegExp(r'^[0-9]{10}$').hasMatch(input);

  bool _isStrongPassword(String input) {
    if (input.length < 8) return false;
    final hasUpper = input.contains(RegExp(r'[A-Z]'));
    final hasNumber = input.contains(RegExp(r'[0-9]'));
    final hasSpecial = input.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    return hasUpper && hasNumber && hasSpecial;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _auth.register(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      village: _selectedVillage!.trim(),
      district: _selectedDistrict!.trim(),
      state: _selectedState!,
      gender: _selectedGender,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('villager_onboarded', true);
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login to continue.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedGender = null;
        _selectedState = null;
        _selectedDistrict = null;
        _selectedVillage = null;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VillagerLoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districts = _selectedState != null ? (_districtsByState[_selectedState!] ?? []) : const <String>[];
    final villages = _selectedDistrict != null ? (_villagesByDistrict[_selectedDistrict!] ?? []) : const <String>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Villager Sign Up'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.public, size: 20, color: Colors.black54),
                    onSelected: (code) => LocaleController.instance.setLocale(Locale(code)),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'en', child: Text('English')),
                      PopupMenuItem(value: 'hi', child: Text('हिन्दी')),
                      PopupMenuItem(value: 'ne', child: Text('नेपाली')),
                      PopupMenuItem(value: 'as', child: Text('অসমীয়া')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: const [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Create your villager account',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Report water issues, view alerts, and protect your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Phone number is required';
                        if (!_isValidPhone(value)) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      value: _selectedState,
                      items: _states
                          .map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedDistrict = null;
                          _selectedVillage = null;
                        });
                      },
                      validator: (value) => value == null ? 'State is required' : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      value: _selectedDistrict,
                      items: districts
                          .map((district) => DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                          _selectedVillage = null;
                        });
                      },
                      validator: (value) => value == null ? 'District is required' : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Village',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                      value: _selectedVillage,
                      items: villages
                          .map((village) => DropdownMenuItem(
                                value: village,
                                child: Text(village),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedVillage = value),
                      validator: (value) => value == null ? 'Village is required' : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Gender (optional)',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      value: _selectedGender,
                      items: _genders
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedGender = value),
                      validator: (_) => null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (!_isStrongPassword(value)) {
                          return 'Min 8 chars with uppercase, number, and special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        if (!_isStrongPassword(value)) return 'Password requirements not met';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: Color(0xFF64748B))),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const VillagerLoginPage()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
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

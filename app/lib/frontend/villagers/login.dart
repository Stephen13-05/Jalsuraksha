import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/frontend/villagers/signup.dart';
import 'package:app/frontend/villagers/dashboard.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/services/villager_auth_service.dart';

class VillagerLoginPage extends StatefulWidget {
  const VillagerLoginPage({super.key});

  @override
  State<VillagerLoginPage> createState() => _VillagerLoginPageState();
}

class _VillagerLoginPageState extends State<VillagerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = VillagerAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) => RegExp(r'^[0-9]{10}$').hasMatch(input);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a valid phone number and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _auth.login(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      final data = result.userData ?? const {};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('villager_uid', (data['uid'] ?? '').toString());
      await prefs.setString('villager_name', (data['fullName'] ?? '').toString());
      await prefs.setString('villager_village', (data['village'] ?? '').toString());
      await prefs.setString('villager_district', (data['district'] ?? '').toString());
      await prefs.setString('villager_state', (data['state'] ?? '').toString());
      await prefs.setString('villager_phone', (data['phoneNumber'] ?? '').toString());

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VillagerDashboardPage(
            uid: (data['uid'] ?? '').toString(),
            fullName: (data['fullName'] ?? 'Villager').toString(),
            village: (data['village'] ?? 'Unknown').toString(),
            district: (data['district'] ?? 'Unknown').toString(),
            state: (data['state'] ?? '').toString().isEmpty ? null : (data['state'] ?? '').toString(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                    icon: const Icon(Icons.public, color: Colors.black54),
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
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Color(0x15000000), blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.water_drop, size: 64, color: Color(0xFF0EA5E9))),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Villager Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Access your community dashboard, report sanitation issues, and stay informed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_in_talk_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Phone number is required';
                        if (!_isValidPhone(value)) return 'Enter a 10-digit phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
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
                        if (value.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Forgot password support will be available soon.')),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
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
                                'Login',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New to Jal Suraksha? ', style: TextStyle(color: Color(0xFF64748B))),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const VillagerSignUpPage()),
                            );
                          },
                    child: Text(
                      'Sign Up',
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

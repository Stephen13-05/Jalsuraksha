import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/frontend/Localclincs/Signup.dart';
import 'package:app/frontend/Localclincs/Dashboard.dart';
import 'package:app/locale/locale_controller.dart';

class ClinicLoginPage extends StatefulWidget {
  const ClinicLoginPage({super.key});

  @override
  State<ClinicLoginPage> createState() => _ClinicLoginPageState();
}

class _ClinicLoginPageState extends State<ClinicLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) => RegExp(r'^[0-9]{10}$').hasMatch(input);
  
  bool _isValidPassword(String input) {
    // Password must be at least 8 characters and contain both letters and numbers
    return input.length >= 8 && 
           RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$').hasMatch(input);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('form_fix_errors'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // TODO: Implement login logic with backend
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    // Navigate to dashboard after successful login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    
    // Navigate to Dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ClinicDashboard()),
    );
  }

  // Match visual style with Signup page: filled grey boxes, rounded corners
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('clinic_login')),
        centerTitle: true,
        elevation: 0,
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
                          // Apply language change globally for all users
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
              const SizedBox(height: 40),
              
              // Phone Number Field
              _boxedField(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16),
                  decoration: _filledDecoration(
                    hint: localizations.t('mobile_hint'),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 22),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.t('mobile_required');
                    }
                    if (!_isValidPhone(value)) {
                      return localizations.t('mobile_invalid');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Password Field
              _boxedField(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16),
                  decoration: _filledDecoration(
                    hint: localizations.t('password'),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF), size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.t('field_required');
                    }
                    if (!_isValidPassword(value)) {
                      return localizations.t('password_validation_error');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: Text(
                    localizations.t('forgot_password'),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                        localizations.t('login'),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.t('dont_have_account'),
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ClinicSignUpPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localizations.t('sign_up'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
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

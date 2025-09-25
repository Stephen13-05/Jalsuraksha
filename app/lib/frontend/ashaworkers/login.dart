import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/frontend/ashaworkers/home.dart';
import 'package:app/frontend/ashaworkers/signup.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/services/asha_auth_service.dart';

class AshaWorkerLoginPage extends StatefulWidget {
  const AshaWorkerLoginPage({Key? key}) : super(key: key);

  @override
  _AshaWorkerLoginPageState createState() => _AshaWorkerLoginPageState();
}

class _AshaWorkerLoginPageState extends State<AshaWorkerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AshaAuthService _authService = AshaAuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String input) {
    return RegExp(r'^[0-9]{10}$').hasMatch(input);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Attempt to login using the Firestore-backed ASHA auth service
        final result = await _authService.login(
          _phoneController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        if (result.isSuccess) {
          // Mark as returning user and persist ASHA identity for scoping
          try {
            // ignore: use_build_context_synchronously
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isReturningUser', true);
            final data = result.userData ?? const {};
            await prefs.setString('asha_uid', (data['uid'] ?? '').toString());
            await prefs.setString('asha_id', (data['ashaId'] ?? '').toString());
            await prefs.setString('asha_name', (data['name'] ?? '').toString());
            await prefs.setString('asha_state', (data['state'] ?? '').toString());
            await prefs.setString('asha_district', (data['district'] ?? '').toString());
            await prefs.setString('asha_village', (data['village'] ?? '').toString());
            await prefs.setString('asha_phone', (data['phoneNumber'] ?? '').toString());
          } catch (_) {}
          // Navigate to home page on successful login, passing the user's profile context
          final userName = result.userData?['name'] as String?;
          final village = result.userData?['village'] as String?;
          final district = result.userData?['district'] as String?;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AshaWorkerHomePage(
                userName: userName,
                village: village,
                district: district,
              ),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Login failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show a quick hint if validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 10-digit phone number and a 10-character password with uppercase and special character.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top-right language selector
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
                const SizedBox(height: 8),
                // Centered Logo
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    height: 150,
                    child: Image(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Headline
                Center(
                  child: Text(
                    AppLocalizations.of(context).t('title_welcome'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppLocalizations.of(context).t('subtitle_login'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Phone Number Field (prefix icon on the left)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).t('hint_phone'),
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 22),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                const SizedBox(height: 16),
                // Password Field (filled, rounded, suffix icon)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).t('hint_password'),
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).t('password_empty');
                    }
                    final hasUpper = value.contains(RegExp(r'[A-Z]'));
                    final hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
                    if (value.length != 10 || !hasUpper || !hasSpecial) {
                      return 'Password must be exactly 10 characters, include at least one uppercase letter and one special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Forgot Password link
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppLocalizations.of(context).t('forgot_password'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Login Button
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
                            AppLocalizations.of(context).t('login'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom Sign Up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('no_account'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AshaWorkerSignUpPage(),
                                ),
                              );
                            },
                      child: Text(
                        AppLocalizations.of(context).t('sign_up'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

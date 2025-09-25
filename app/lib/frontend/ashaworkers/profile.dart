import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/locale/locale_controller.dart';
import 'package:app/frontend/ashaworkers/home.dart';
import 'package:app/frontend/ashaworkers/reports.dart';
import 'package:app/frontend/ashaworkers/data_collection.dart';
import 'package:app/frontend/ashaworkers/analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/services/asha_auth_service.dart';
import 'package:app/frontend/ashaworkers/login.dart';

class AshaWorkerProfilePage extends StatefulWidget {
  const AshaWorkerProfilePage({super.key});

  @override
  State<AshaWorkerProfilePage> createState() => _AshaWorkerProfilePageState();
}

class _AshaWorkerProfilePageState extends State<AshaWorkerProfilePage> {
  int _currentIndex = 4;
  String? _uid;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('asha_uid');
    setState(() { _uid = uid; });
    if (uid != null && uid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('appdata')
            .doc('main')
            .collection('users')
            .doc(uid)
            .get();
        setState(() {
          _user = doc.data() ?? {};
          _loading = false;
        });
      } catch (_) {
        setState(() { _loading = false; });
      }
    } else {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          t('profile_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 12),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1550525811-e5869dd03032?q=80&w=200&auto=format&fit=crop',
              ),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          const SizedBox(height: 16),

          // Name and basic details
          Center(
            child: Column(
              children: [
                Text(
                  (_user?['name'] ?? 'ASHA Worker') as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t('worker_id_prefix')} ${(_user?['ashaId'] ?? '—')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Change Language (Expansion)
          _SectionCard(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: const Icon(Icons.public),
                title: Text(
                  t('change_language'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: const [
                  _LanguageRow(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Personal Information
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              t('personal_information'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _InfoTile(
            icon: Icons.person_outline,
            titleKey: 'name_label',
            value: (_user?['name'] ?? '—').toString(),
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            titleKey: 'worker_id_label',
            value: (_user?['ashaId'] ?? '—').toString(),
          ),
          _InfoTile(
            icon: Icons.map_outlined,
            titleKey: 'district_label',
            value: (_user?['district'] ?? '—').toString(),
          ),
          _InfoTile(
            icon: Icons.location_city_outlined,
            titleKey: 'village_label',
            value: (_user?['village'] ?? '—').toString(),
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            titleKey: 'contact_number_label',
            value: (_user?['phoneNumber'] ?? '—').toString(),
            valueColor: cs.primary,
          ),

          const SizedBox(height: 10),

          // Support
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              t('support'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ActionTile(icon: Icons.help_outline, label: t('help_faqs'), onTap: () {}),
          _ActionTile(icon: Icons.headset_mic_outlined, label: t('contact_admin'), onTap: () {}),

          const SizedBox(height: 10),

          // Account Management
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              t('account_management'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ActionTile(
            icon: Icons.edit_outlined,
            label: t('edit_profile'),
            onTap: () async {
              if (_uid == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required')));
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _EditProfilePage(
                    uid: _uid!,
                    initial: {
                      'name': _user?['name'] ?? '',
                      'phoneNumber': _user?['phoneNumber'] ?? '',
                      'district': _user?['district'] ?? '',
                      'village': _user?['village'] ?? '',
                    },
                  ),
                ),
              );
              _load();
            },
          ),
          _ActionTile(
            icon: Icons.lock_outline,
            label: t('change_password'),
            onTap: () {
              if (_uid == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required')));
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _ChangePasswordPage(uid: _uid!)),
              );
            },
          ),
          _ActionTile(
            icon: Icons.logout,
            label: t('logout'),
            trailing: const Icon(Icons.arrow_right_alt),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AshaWorkerLoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),

      // Bottom Navigation (5 tabs)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AshaWorkerHomePage()),
                (route) => false,
              );
            } else if (i == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AshaWorkerDataCollectionPage(),
                ),
              );
            } else if (i == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AshaWorkerReportsPage()),
              );
            } else if (i == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AshaWorkerAnalyticsPage()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: cs.primary,
          unselectedItemColor: const Color(0xFF9CA3AF),
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: t('nav_home_title')),
            BottomNavigationBarItem(icon: const Icon(Icons.fact_check_outlined), label: t('nav_data_collection')),
            BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: t('nav_reports')),
            BottomNavigationBarItem(icon: const Icon(Icons.insert_chart_outlined), label: t('nav_analytics')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), label: t('nav_profile')),
          ],
        ),
      ),
    );
  }
}

// ===== Edit Profile Page =====
class _EditProfilePage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> initial;
  const _EditProfilePage({required this.uid, required this.initial});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _district;
  late TextEditingController _village;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: (widget.initial['name'] ?? '').toString());
    _phone = TextEditingController(text: (widget.initial['phoneNumber'] ?? '').toString());
    _district = TextEditingController(text: (widget.initial['district'] ?? '').toString());
    _village = TextEditingController(text: (widget.initial['village'] ?? '').toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _district.dispose();
    _village.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = AshaAuthService();
    final data = {
      'name': _name.text.trim(),
      'phoneNumber': _phone.text.trim(),
      'district': _district.text.trim(),
      'village': _village.text.trim(),
    };
    final res = await svc.updateProfile(widget.uid, data);
    setState(() => _saving = false);
    if (!mounted) return;
    if (res.isSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('asha_name', _name.text.trim());
      await prefs.setString('asha_district', _district.text.trim());
      await prefs.setString('asha_village', _village.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Update failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.length < 10) ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'District'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _village,
                decoration: const InputDecoration(labelText: 'Village'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Change Password Page =====
class _ChangePasswordPage extends StatefulWidget {
  final String uid;
  const _ChangePasswordPage({required this.uid});

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _isStrong(String v) {
    final hasUpper = v.contains(RegExp(r'[A-Z]'));
    final hasSpecial = v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    return v.length == 10 && hasUpper && hasSpecial;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = AshaAuthService();
    final res = await svc.changePassword(uid: widget.uid, oldPassword: _old.text, newPassword: _new.text);
    setState(() => _saving = false);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to change password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _old,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old password'),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter old password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password (10 chars, 1 uppercase, 1 special)'),
                validator: (v) => (v == null || !_isStrong(v)) ? 'Weak password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (v) => (v != _new.text) ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Change Password'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: const [
        _LangChip(label: 'English', code: 'en'),
        _LangChip(label: 'हिन्दी', code: 'hi'),
        _LangChip(label: 'नेपाली', code: 'ne'),
        _LangChip(label: 'অসমীয়া', code: 'as'),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String code;
  const _LangChip({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (_) => LocaleController.instance.setLocale(Locale(code)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.titleKey,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        t(titleKey),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: valueColor ?? Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
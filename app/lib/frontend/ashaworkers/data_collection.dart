import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/frontend/ashaworkers/home.dart';
import 'package:app/frontend/ashaworkers/reports.dart';
import 'package:app/frontend/ashaworkers/profile.dart';
import 'package:app/frontend/ashaworkers/navigation.dart';
import 'package:app/frontend/ashaworkers/bluetooth_sync.dart';
import 'package:app/frontend/ashaworkers/offline_sync.dart';

class AshaWorkerDataCollectionPage extends StatefulWidget {
  const AshaWorkerDataCollectionPage({super.key});

  @override
  State<AshaWorkerDataCollectionPage> createState() =>
      _AshaWorkerDataCollectionPageState();
}

class _AshaWorkerDataCollectionPageState
    extends State<AshaWorkerDataCollectionPage> {
  AshaNavTab _currentTab = AshaNavTab.dataCollection;

  // Household details
  final _doorNo = TextEditingController();
  final _headName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _village = TextEditingController();
  final _district = TextEditingController();

  // Family members
  final List<_Member> _members = [];

  // Additional details
  String? _waterSource; // e.g., Tap, Handpump, Well, River, Other
  final _waterPh = TextEditingController();
  final _turbidity = TextEditingController();
  bool? _coliformPresent; // true/false

  // Sanitation / Image attach
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageUrl; // optional link

  // Other flags
  bool _visitedHospital = false;
  bool _submitting = false;
  bool _prefLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAshaDefaults();
  }

  Future<void> _loadAshaDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ashaVillage = (prefs.getString('asha_village') ?? '').trim();
      final ashaDistrict = (prefs.getString('asha_district') ?? '').trim();
      if (!mounted) return;
      setState(() {
        if (ashaVillage.isNotEmpty) _village.text = ashaVillage;
        if (ashaDistrict.isNotEmpty) _district.text = ashaDistrict;
        _prefLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _prefLoaded = true);
    }
  }

  @override
  void dispose() {
    _doorNo.dispose();
    _headName.dispose();
    _phone.dispose();
    _address.dispose();
    _village.dispose();
    _district.dispose();
    _waterPh.dispose();
    _turbidity.dispose();
    super.dispose();
  }

  // UI helpers
  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Future<void> _showAttachImageSheet() async {
    final t = AppLocalizations.of(context).t;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach image',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final XFile? file = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1600,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          if (!mounted) return;
                          setState(() {
                            _imageBytes = bytes;
                            _imageUrl = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(t('camera')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final XFile? file = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1600,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          if (!mounted) return;
                          setState(() {
                            _imageUrl = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _promptImageUrl();
                  },
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Attach via link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptImageUrl() async {
    final controller = TextEditingController(text: _imageUrl ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach via link',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: _decoration('Image URL'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).t('cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Attach'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() => _imageUrl = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image attached'),
        ),
      );
    }
  }

  Future<void> _showAddMemberSheet() async {
    final t = AppLocalizations.of(context).t;
    final name = TextEditingController();
    final age = TextEditingController();
    final phone = TextEditingController();
    final symptoms = TextEditingController();
    String gender = 'Female';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool isMinor() {
              final a = int.tryParse(age.text.trim());
              return a != null && a < 18;
            }

            void onAgeChanged(String _) {
              if (isMinor()) phone.text = _phone.text.trim();
              setSheetState(() {});
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('add_member_title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: _decoration(t('name')),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: age,
                          keyboardType: TextInputType.number,
                          onChanged: onAgeChanged,
                          decoration: _decoration(t('age')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InputDecorator(
                          decoration: _decoration(t('gender')),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: gender,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  gender = v;
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    enabled: !isMinor(),
                    decoration: _decoration(t('phone_number')).copyWith(
                      helperText: isMinor()
                          ? t('auto_filled_minor_helper')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: symptoms,
                    decoration: _decoration(t('symptoms_hint')),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(t('cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (name.text.trim().isEmpty ||
                              age.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t('enter_name_age'))),
                            );
                            return;
                          }
                          final isUnder18 =
                              int.tryParse(age.text.trim()) != null &&
                              int.parse(age.text.trim()) < 18;
                          final memberPhone = isUnder18
                              ? _phone.text.trim()
                              : phone.text.trim();
                          setState(() {
                            _members.add(
                              _Member(
                                name: name.text.trim(),
                                gender: gender,
                                age: age.text.trim(),
                                phone: memberPhone,
                                symptoms: symptoms.text.trim(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(t('add')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveToFirestore({required bool draft}) async {
    final t = AppLocalizations.of(context).t;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ashaUid = prefs.getString('asha_uid');
      final ashaId = prefs.getString('asha_id');
      final ashaName = prefs.getString('asha_name');
      final ashaVillage = prefs.getString('asha_village');
      final ashaDistrict = prefs.getString('asha_district');

      // Prepare members
      final members = _members
          .map(
            (m) => {
              'name': m.name,
              'gender': m.gender,
              'age': m.age,
              'phone': m.phone,
              'symptoms': m.symptoms,
            },
          )
          .toList();

      // Validate when submitting
      double? ph = double.tryParse(_waterPh.text.trim());
      double? turb = double.tryParse(_turbidity.text.trim());
      if (!draft) {
        if (ph == null || ph < 0 || ph > 14) {
          throw Exception('Water pH must be between 0 and 14');
        }
        if (turb == null || turb < 0 || turb > 100) {
          throw Exception('Turbidity (NTU) must be between 0 and 100');
        }
        if (_coliformPresent == null) {
          throw Exception('Please select coliform presence');
        }
      }

      String? imageBytesBase64;
      if (_imageBytes != null && _imageBytes!.isNotEmpty) {
        imageBytesBase64 = base64Encode(_imageBytes!);
      }

      final data = {
        'asha': {
          'uid': ashaUid,
          'ashaId': ashaId,
          'name': ashaName,
          'village': ashaVillage,
          'district': ashaDistrict,
        },
        'household': {
          'doorNo': _doorNo.text.trim(),
          'headName': _headName.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'village': _village.text.trim(),
          'district': _district.text.trim(),
        },
        'members': members,
        'additional': {
          'waterSource': _waterSource,
          'waterPH': ph,
          'turbidityNTU': turb,
          'coliformPresent': _coliformPresent,
          'visitedHospital': _visitedHospital,
        },
        'image': {
          'imageUrl': _imageUrl,
          if (imageBytesBase64 != null) 'imageBytesBase64': imageBytesBase64,
        },
        'status': draft ? 'draft' : 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final CollectionReference<Map<String, dynamic>> targetCol =
          (ashaUid != null && ashaUid.isNotEmpty)
          ? FirebaseFirestore.instance
                .collection('appdata')
                .doc('main')
                .collection('ashwadata')
                .doc(ashaUid)
                .collection('household_surveys')
          : FirebaseFirestore.instance.collection('household_surveys');

      final docRef = await targetCol.add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft
                ? 'Draft saved'
                : 'Form submitted (ID: ${docRef.id})',
          ),
        ),
      );

      if (!draft) {
        setState(() {
          _doorNo.clear();
          _headName.clear();
          _phone.clear();
          _address.clear();
          _waterSource = null;
          _waterPh.clear();
          _turbidity.clear();
          _coliformPresent = null;
          _imageUrl = null;
          _imageBytes = null;
          _visitedHospital = false;
          _members.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.85)],
            ),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          t('dc_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      drawer: AshaNavDrawer(
        currentTab: _currentTab,
        onSelectTab: _handleNavSelection,
        onBluetoothSync: _openBluetoothSync,
        onOfflineSync: _openOfflineSync,
        onChangeLanguage: () => showLanguagePicker(context),
      ),
      body: !_prefLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Household Details', color1: Color(0xFF14B8A6), color2: Color(0xFF60A5FA)),
                  const SizedBox(height: 12),
                  _CardWrap(
                    children: [
                      TextField(
                        controller: _doorNo,
                        decoration: _decoration('Household Door No', icon: Icons.meeting_room),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _headName,
                        decoration: _decoration('Head of Household Name', icon: Icons.person_outline),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration('Phone Number', icon: Icons.call),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _address,
                        decoration: _decoration('Address', icon: Icons.home_outlined),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _village,
                              readOnly: true,
                              decoration:
                                  _decoration('Village', icon: Icons.location_city).copyWith(
                                    suffixIcon: const Icon(Icons.lock_outline),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _district,
                              readOnly: true,
                              decoration:
                                  _decoration('District', icon: Icons.map_outlined).copyWith(
                                    suffixIcon: const Icon(Icons.lock_outline),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const _SectionHeader(title: 'Family Members', color1: Color(0xFFF97316), color2: Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  _CardWrap(
                    children: [
                      if (_members.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text('No members added yet'),
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < _members.length; i++)
                              _MemberTile(
                                member: _members[i],
                                onDelete: () =>
                                    setState(() => _members.removeAt(i)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _showAddMemberSheet,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Add member'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const _SectionHeader(title: 'Additional Details', color1: Color(0xFF8B5CF6), color2: Color(0xFF06B6D4)),
                  const SizedBox(height: 12),
                  _CardWrap(
                    children: [
                      InputDecorator(
                        decoration: _decoration('Water Source').copyWith(
                          prefixIcon: const Icon(Icons.water_drop_outlined),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _waterSource,
                            hint: const Text('Select source'),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'Tap',
                                child: Text('Tap'),
                              ),
                              DropdownMenuItem(
                                value: 'Handpump',
                                child: Text('Handpump'),
                              ),
                              DropdownMenuItem(
                                value: 'Well',
                                child: Text('Well'),
                              ),
                              DropdownMenuItem(
                                value: 'River',
                                child: Text('River'),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _waterSource = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _waterPh,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _decoration(
                                'pH',
                                icon: Icons.science,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _turbidity,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _decoration(
                                'Turbidity (NTU)',
                                icon: Icons.opacity,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: _decoration('Coliform Presence')
                            .copyWith(
                              prefixIcon: const Icon(Icons.bloodtype_outlined),
                            ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _coliformPresent,
                            hint: const Text('Select'),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: true,
                                child: Text('Present'),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Absent'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _coliformPresent = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _visitedHospital,
                        onChanged: (v) => setState(() => _visitedHospital = v),
                        title: const Text('Visited hospital?'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const _SectionHeader(title: 'Sanitation Report', color1: Color(0xFF10B981), color2: Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  _CardWrap(
                    children: [
                      if (_imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 140,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 8),
                              const Text('No image attached'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _showAttachImageSheet,
                            icon: const Icon(Icons.attachment_outlined),
                            label: const Text('Attach image'),
                          ),
                          if (_imageBytes != null ||
                              (_imageUrl != null && _imageUrl!.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => setState(() {
                                _imageBytes = null;
                                _imageUrl = null;
                              }),
                              icon: const Icon(Icons.clear),
                              label: const Text('Remove'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _submitting
                              ? null
                              : () => _saveToFirestore(draft: true),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save draft'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _submitting
                              ? null
                              : () => _saveToFirestore(draft: false),
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

      // Floating button -> quick actions (QR, Voice)
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          heroTag: 'dc_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAction(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan QR',
                        onTap: () {
                          Navigator.pop(ctx); /* TODO: implement */
                        },
                      ),
                      _QuickAction(
                        icon: Icons.mic_outlined,
                        label: 'Voice bot',
                        onTap: () {
                          Navigator.pop(ctx); /* TODO: implement */
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: const Icon(Icons.auto_awesome),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _handleNavSelection(AshaNavTab tab) {
    if (tab == _currentTab) return;
    switch (tab) {
      case AshaNavTab.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerHomePage()),
        );
        break;
      case AshaNavTab.dataCollection:
        setState(() => _currentTab = AshaNavTab.dataCollection);
        break;
      case AshaNavTab.reports:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerReportsPage()),
        );
        break;
      case AshaNavTab.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AshaWorkerProfilePage()),
        );
        break;
    }
  }

  void _openBluetoothSync() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AshaWorkerBluetoothSyncPage()),
    );
  }

  void _openOfflineSync() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AshaWorkerOfflineSyncPage()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Member {
  final String name;
  final String gender;
  final String age;
  final String phone;
  final String symptoms;
  _Member({
    required this.name,
    required this.gender,
    required this.age,
    required this.phone,
    required this.symptoms,
  });
}

class _MemberTile extends StatelessWidget {
  final _Member member;
  final VoidCallback onDelete;
  const _MemberTile({required this.member, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _pill('${member.gender}'),
                    _pill('Age: ${member.age}'),
                    _pill(member.phone.isNotEmpty ? member.phone : '-'),
                    if (member.symptoms.isNotEmpty) _pill(member.symptoms),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color1;
  final Color color2;
  const _SectionHeader({required this.title, required this.color1, required this.color2});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ) ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color1.withOpacity(0.9), color2.withOpacity(0.9)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardWrap extends StatelessWidget {
  final List<Widget> children;
  const _CardWrap({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

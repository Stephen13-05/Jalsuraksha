import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/villager_data_service.dart';

class VillagerReportIssueTab extends StatefulWidget {
  const VillagerReportIssueTab({
    super.key,
    required this.uid,
    required this.village,
    required this.district,
  });

  final String uid;
  final String village;
  final String district;

  @override
  State<VillagerReportIssueTab> createState() => _VillagerReportIssueTabState();
}

class _VillagerReportIssueTabState extends State<VillagerReportIssueTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  final _picker = ImagePicker();
  final _service = VillagerDataService();

  bool _isSubmitting = false;
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _service.uploadIssueImage(file: _selectedImage!, uid: widget.uid);
    }

    try {
      await _service.submitIssue(
        uid: widget.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        village: widget.village,
        district: widget.district,
        imageUrl: imageUrl,
        extra: {
          'details': _additionalInfoController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue submitted successfully. Thank you for reporting!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _additionalInfoController.clear();
      setState(() => _selectedImage = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit issue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _titleController,
                label: 'Issue Title',
                hint: 'Short headline (e.g., Muddy tap water)',
                icon: Icons.title,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter an issue title'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(),
              const SizedBox(height: 16),
              _buildMultilineField(
                controller: _descriptionController,
                label: 'Describe the issue',
                hint: 'Explain what is happening, when it started, and who is affected.',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),
              _buildMultilineField(
                controller: _additionalInfoController,
                label: 'Additional details (optional)',
                hint: 'Provide any extra context or suggestions for action.',
                icon: Icons.lightbulb_outline,
                required: false,
              ),
              const SizedBox(height: 20),
              _buildImagePicker(theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Issue',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Report Sanitation Issue',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Help local authorities respond faster by sharing detailed reports. Photos help validate the issue quicker.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    const categories = [
      'Drinking Water',
      'Drainage',
      'Toilet Hygiene',
      'Waste Disposal',
      'Mosquito Breeding',
      'Other',
    ];

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select issue category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
          .toList(),
      onChanged: (value) => _categoryController.text = value ?? '',
      validator: (value) => (value == null || value.isEmpty) ? 'Please select a category' : null,
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      minLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              if (value.trim().length < 20) {
                return 'Please provide at least 20 characters';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach photo (optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
              child: _ImagePickerOption(
                icon: Icons.photo_camera_outlined,
                label: 'Camera',
                gradient: const [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
              child: _ImagePickerOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                gradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _isSubmitting ? null : () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Remove photo',
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No photo selected yet',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Helpful tips before submitting',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
          ),
          SizedBox(height: 8),
          Text('• Provide exact location details in the description.'),
          Text('• Mention if any households or individuals are affected.'),
          Text('• Photos should capture the issue clearly for faster verification.'),
        ],
      ),
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  const _ImagePickerOption({required this.icon, required this.label, required this.gradient});

  final IconData icon;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

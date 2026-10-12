import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/main.dart';

import '../../../config/typography/app_typography.dart';
import '../../../core/common_widgets/custom_app_button.dart';
import '../../../core/common_widgets/custom_text_field.dart';
import '../models/lead_model.dart';

class AddLeadScreen extends StatefulWidget {
  final LeadModel? lead;

  const AddLeadScreen({super.key, this.lead});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _proposalLinkController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _visitingCardImage;
  final List<File> _documentImages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.lead != null) {
      final lead = widget.lead!;
      _nameController.text = lead.name;
      _contactController.text = lead.contactInfo;
      _addressController.text = lead.address;
      _companyController.text = lead.companyName ?? '';
      _notesController.text = lead.notes ?? '';
      _proposalLinkController.text = lead.proposalLink ?? '';
      _visitingCardImage = lead.visitingCardImagePath != null ? File(lead.visitingCardImagePath!) : null;
      _documentImages.addAll(lead.documentImagePaths.map((path) => File(path)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    _proposalLinkController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickVisitingCardImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200);

      if (pickedFile != null) {
        setState(() => _visitingCardImage = File(pickedFile.path));
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to pick image: $e');
    }
  }

  Future<void> _pickDocumentImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200);

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _documentImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to pick images: $e');
    }
  }

  void _removeDocumentImage(int index) => setState(() => _documentImages.removeAt(index));

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_nameController.text.isEmpty) {
      AppPrompts.showError(message: 'Please enter lead name');
      return false;
    }

    if (_contactController.text.isEmpty) {
      AppPrompts.showError(message: 'Please enter contact information');
      return false;
    }

    return true;
  }

  Future<void> _saveLead() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final visitingCardPath = _visitingCardImage?.path;
      final documentPaths = _documentImages.map((file) => file.path).toList();

      final lead = LeadModel(
        id: widget.lead?.id,
        address: _addressController.text.trim(),
        name: _nameController.text.trim(),
        contactInfo: _contactController.text.trim(),
        companyName: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        visitingCardImagePath: visitingCardPath,
        documentImagePaths: documentPaths,
        proposalLink: _proposalLinkController.text.trim().isNotEmpty ? _proposalLinkController.text.trim() : null,
      );

      final activityType = widget.lead != null ? 'Updated' : 'Created';
      final updatedLead = lead.addActivity(
        activityType,
        'Lead ${widget.lead != null ? 'updated' : 'created'} via mobile app',
      );

await leadController.addLead(updatedLead);

      AppPrompts.showSuccess(message: widget.lead != null ? 'Lead updated successfully!' : 'Lead added successfully!');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppPrompts.showError(message: 'Failed to save lead: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLead() => AppPrompts.showConfirmation(
    context: context,
    title: 'Delete Lead',
    message: 'Are you sure you want to delete this lead? This action cannot be undone.',
    onConfirm: () async {
      setState(() => _isLoading = true);

      try {
        await leadController.deleteLead(widget.lead!);
        AppPrompts.showSuccess(message: 'Lead deleted successfully!');
        Get.back();
      } catch (e) {
        AppPrompts.showError(message: 'Failed to delete lead: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.lead != null ? 'Edit Lead' : 'Add New Lead'),
      flexibleSpace: AppUtils.gradientFlexibleSpace(),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      actions: [
        if (widget.lead != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : _deleteLead,
          ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Information Section
          Text('Basic Information', style: AppTypography.style18SemiBold),
          const SizedBox(height: 20),

          // Name Field
          CustomTextField(
            controller: _nameController,
            headingLabelText: 'Name',
            isRequired: true,
            hintText: 'Enter lead name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter lead name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Contact Field
          CustomTextField(
            controller: _contactController,
            headingLabelText: 'Contact Information',
            isRequired: true,
            hintText: 'Phone number',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact information';
              } else if (!GetUtils.isPhoneNumber(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address Field
          CustomTextField(
            controller: _addressController,
            headingLabelText: 'Address',
            isRequired: true,
            hintText: 'Enter address',
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Company Field
          CustomTextField(
            controller: _companyController,
            headingLabelText: 'Company Name',
            hintText: 'Enter company name (optional)',
          ),
          const SizedBox(height: 24),

          // Attachments Section
          Text('Attachments', style: AppTypography.style18SemiBold),
          const SizedBox(height: 16),
          _buildImagePickerSection(),
          const SizedBox(height: 24),

          // Additional Information Section
          Text('Additional Information', style: AppTypography.style18SemiBold),
          const SizedBox(height: 16),

          // Notes Field
          CustomTextField(
            controller: _notesController,
            headingLabelText: 'Notes',
            hintText: 'Add any notes about the lead...',
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 16),

          // Proposal Link Field
          CustomTextField(
            controller: _proposalLinkController,
            headingLabelText: 'Proposal Link',
            hintText: 'https://example.com/proposal',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 32),

          // Save Button
          Center(
            child: CustomAppButton(
              text: widget.lead != null ? 'Update Lead' : 'Save Lead',
              onPressed: _isLoading ? null : _saveLead,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget _buildImagePickerSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Visiting Card', style: AppTypography.style16SemiBold),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickVisitingCardImage,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 69, 69, 69),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: _visitingCardImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _visitingCardImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Tap to add visiting card', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 20),
      Text('Documents', style: AppTypography.style16SemiBold),
      const SizedBox(height: 8),
      if (_documentImages.isNotEmpty)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _documentImages.length,
            itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: 12),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color.fromARGB(255, 69, 69, 69),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_documentImages[index], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeDocumentImage(index),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      Container(
        height: 57,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 69, 69, 69),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: TextButton(
          onPressed: _pickDocumentImages,
          style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_file_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Add Documents', style: AppTypography.style16SemiBold.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    ],
  );
}

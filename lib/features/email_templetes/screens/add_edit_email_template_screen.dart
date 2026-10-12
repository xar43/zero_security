import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';

import '../../../core/common_widgets/custom_app_button.dart';
import '../../../core/common_widgets/custom_text_field.dart';
import '../../../core/utils/app_prompts.dart';
import '../controller/email_template_controller.dart';
import '../models/email_template_model.dart';

Future<dynamic> showAddEditEmailTemplateSheet(
    BuildContext context, {
      EmailTemplateModel? template,
    }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.kAppBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AddEditEmailTemplateSheet(template: template, scrollController: scrollController),
        );
      },
    ),
  );
}

class AddEditEmailTemplateSheet extends StatefulWidget {
  final EmailTemplateModel? template;
  final ScrollController scrollController;

  const AddEditEmailTemplateSheet({super.key, this.template, required this.scrollController});

  @override
  State<AddEditEmailTemplateSheet> createState() =>
      _AddEditEmailTemplateSheetState();
}

class _AddEditEmailTemplateSheetState extends State<AddEditEmailTemplateSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController fromNameCtrl;
  late final TextEditingController fromEmailCtrl;
  late final TextEditingController toEmailCtrl;
  late final TextEditingController ccEmailCtrl;
  late final TextEditingController bccEmailCtrl;
  late final TextEditingController subjectCtrl;
  late final TextEditingController bodyCtrl;
  late final TextEditingController signatureCtrl;

  final RxBool isValid = false.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  bool get isEdit => widget.template != null;

  // Email validation regex
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();

    titleCtrl = TextEditingController(text: widget.template?.title ?? "");
    fromNameCtrl = TextEditingController(text: widget.template?.fromName ?? "");
    fromEmailCtrl =
        TextEditingController(text: widget.template?.fromEmail ?? "");
    toEmailCtrl = TextEditingController(text: widget.template?.toEmail ?? "");
    ccEmailCtrl = TextEditingController(text: widget.template?.ccEmail ?? "");
    bccEmailCtrl = TextEditingController(text: widget.template?.bccEmail ?? "");
    subjectCtrl = TextEditingController(text: widget.template?.subject ?? "");
    bodyCtrl = TextEditingController(text: widget.template?.body ?? "");
    signatureCtrl =
        TextEditingController(text: widget.template?.signature ?? "");

    // Add listeners for real-time validation
    titleCtrl.addListener(_validateField);
    fromNameCtrl.addListener(_validateField);
    fromEmailCtrl.addListener(_validateField);
    toEmailCtrl.addListener(_validateField);
    ccEmailCtrl.addListener(_validateField);
    bccEmailCtrl.addListener(_validateField);
    subjectCtrl.addListener(_validateField);
    bodyCtrl.addListener(_validateField);
    signatureCtrl.addListener(_validateField);
  }

  void _validateField() {
    final errors = <String, String>{};

    // Required field validations
    if (titleCtrl.text.trim().isEmpty) {
      errors['title'] = 'Template title is required';
    }

    if (fromNameCtrl.text.trim().isEmpty) {
      errors['fromName'] = 'From name is required';
    }

    // Email validations
    if (fromEmailCtrl.text.trim().isEmpty) {
      errors['fromEmail'] = 'From email is required';
    } else if (!emailRegex.hasMatch(fromEmailCtrl.text.trim())) {
      errors['fromEmail'] = 'Enter a valid email address';
    }

    if (toEmailCtrl.text.trim().isEmpty) {
      errors['toEmail'] = 'To email is required';
    } else if (!emailRegex.hasMatch(toEmailCtrl.text.trim())) {
      errors['toEmail'] = 'Enter a valid email address';
    }

    // Optional email validations
    if (ccEmailCtrl.text.trim().isNotEmpty && !emailRegex.hasMatch(ccEmailCtrl.text.trim())) {
      errors['ccEmail'] = 'Enter a valid email address';
    }

    if (bccEmailCtrl.text.trim().isNotEmpty && !emailRegex.hasMatch(bccEmailCtrl.text.trim())) {
      errors['bccEmail'] = 'Enter a valid email address';
    }

    if (subjectCtrl.text.trim().isEmpty) {
      errors['subject'] = 'Subject is required';
    }

    if (bodyCtrl.text.trim().isEmpty) {
      errors['body'] = 'Email body is required';
    }

    if (signatureCtrl.text.trim().isEmpty) {
      errors['signature'] = 'Signature is required';
    }

    fieldErrors.value = errors;
    isValid.value = errors.isEmpty;
    setState(() {});
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    fromNameCtrl.dispose();
    fromEmailCtrl.dispose();
    toEmailCtrl.dispose();
    ccEmailCtrl.dispose();
    bccEmailCtrl.dispose();
    subjectCtrl.dispose();
    bodyCtrl.dispose();
    signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _validateField();

    isLoading.value = true;

    final title = titleCtrl.text.trim();
    final fromName = fromNameCtrl.text.trim();
    final fromEmail = fromEmailCtrl.text.trim();
    final toEmail = toEmailCtrl.text.trim();
    final ccEmail = ccEmailCtrl.text.trim().isEmpty ? null : ccEmailCtrl.text.trim();
    final bccEmail = bccEmailCtrl.text.trim().isEmpty ? null : bccEmailCtrl.text.trim();
    final subject = subjectCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    final signature = signatureCtrl.text.trim();

    try {
      if (isEdit) {
        final updated = EmailTemplateModel(
          id: widget.template!.id,
          title: title,
          fromName: fromName,
          fromEmail: fromEmail,
          toEmail: toEmail,
          ccEmail: ccEmail ?? "",
          bccEmail: bccEmail ?? "",
          subject: subject,
          body: body,
          signature: signature,
        );

        await EmailTemplateController.updateTemplate(updated);
        Get.back(result: true);
        AppPrompts.showSuccess(message: 'Email template updated successfully');
      } else {
        final newTemplate = EmailTemplateModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          fromName: fromName,
          fromEmail: fromEmail,
          toEmail: toEmail,
          ccEmail: ccEmail ?? "",
          bccEmail: bccEmail ?? "",
          subject: subject,
          body: body,
          signature: signature,
        );

        await EmailTemplateController.addTemplate(newTemplate);
        Get.back(result: true);
        AppPrompts.showSuccess(message: 'Email template added successfully');
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to save template: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Draggable handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? "Update Email Template" : "Create Email Template",
                  style: AppTypography.style20SemiBold.copyWith(color: AppColors.kAppWhite),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: AppColors.kAppWhite),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kAppSecondary.withValues(alpha: .15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      headingLabelText: "Template Title",
                      controller: titleCtrl,
                      hintText: "Enter template title",
                      errorText: fieldErrors['title'],
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "From Name",
                      controller: fromNameCtrl,
                      hintText: "Eg: HR Department",
                      errorText: fieldErrors['fromName'],
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "From Email",
                      controller: fromEmailCtrl,
                      hintText: "Eg: hr@company.com",
                      errorText: fieldErrors['fromEmail'],
                      keyboardType: TextInputType.emailAddress,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "To",
                      controller: toEmailCtrl,
                      hintText: "Eg: client@email.com",
                      errorText: fieldErrors['toEmail'],
                      keyboardType: TextInputType.emailAddress,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "CC",
                      controller: ccEmailCtrl,
                      hintText: "Eg: manager@company.com (Optional)",
                      errorText: fieldErrors['ccEmail'],
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "BCC",
                      controller: bccEmailCtrl,
                      hintText: "Eg: audit@company.com (Optional)",
                      errorText: fieldErrors['bccEmail'],
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "Subject",
                      controller: subjectCtrl,
                      hintText: "Enter email subject",
                      errorText: fieldErrors['subject'],
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "Email Body",
                      controller: bodyCtrl,
                      hintText: "Write your email body here",
                      maxLines: 6,
                      errorText: fieldErrors['body'],
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    _buildField(
                      headingLabelText: "Signature / Regards",
                      controller: signatureCtrl,
                      hintText: "Eg: Regards,\nHR Team\nCompany Name",
                      maxLines: 5,
                      errorText: fieldErrors['signature'],
                      isRequired: true,
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    Obx(
                      () => CustomAppButton(
                        text: isEdit ? "Update Template" : "Create Template",
                        onPressed: _submit,
                        isLoading: isLoading.value,
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String headingLabelText,
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return CustomTextField(
      controller: controller,
      headingLabelText: headingLabelText,
      hintText: hintText,
      errorText: errorText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      isRequired: isRequired,
      headingStyle: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppWhite.withValues(alpha: 0.9)),
      style: AppTypography.style16Regular.copyWith(color: AppColors.kAppWhite),
      hintStyle: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey),
      fillColor: AppColors.kAppBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.kAppPrimary.withValues(alpha: 0.5), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}

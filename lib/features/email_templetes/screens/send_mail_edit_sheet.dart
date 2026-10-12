import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/colors/app_colors.dart';
import '../controller/sent_mail_controller.dart';
import '../models/email_template_model.dart';
import '../models/sent_mail_model.dart';
import '../widgets/email_UI_helpers.dart';

Future<dynamic> showSendMailSheet(
    BuildContext context, {
      required EmailTemplateModel template,
    }) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Send Mail',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (_, animation, __, ___) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(animation),
        child: SendMailSheet(template: template),
      );
    },
  );
}

class SendMailSheet extends StatefulWidget {
  final EmailTemplateModel template;

  const SendMailSheet({super.key, required this.template});

  @override
  State<SendMailSheet> createState() => _SendMailSheetState();
}

class _SendMailSheetState extends State<SendMailSheet> {
  late final TextEditingController fromNameCtrl;
  late final TextEditingController fromEmailCtrl;
  late final TextEditingController toEmailCtrl;
  late final TextEditingController ccEmailCtrl;
  late final TextEditingController bccEmailCtrl;
  late final TextEditingController subjectCtrl;
  late final TextEditingController bodyCtrl;
  late final TextEditingController signatureCtrl;

  final RxBool isValid = false.obs;

  @override
  void initState() {
    super.initState();

    fromNameCtrl = TextEditingController(text: widget.template.fromName);
    fromEmailCtrl = TextEditingController(text: widget.template.fromEmail);
    toEmailCtrl = TextEditingController(text: widget.template.toEmail);
    ccEmailCtrl = TextEditingController(text: widget.template.ccEmail);
    bccEmailCtrl = TextEditingController(text: widget.template.bccEmail);
    subjectCtrl = TextEditingController(text: widget.template.subject);
    bodyCtrl = TextEditingController(text: widget.template.body);
    signatureCtrl = TextEditingController(text: widget.template.signature);

    fromNameCtrl.addListener(_validate);
    fromEmailCtrl.addListener(_validate);
    toEmailCtrl.addListener(_validate);
    subjectCtrl.addListener(_validate);
    bodyCtrl.addListener(_validate);
    signatureCtrl.addListener(_validate);

    _validate();
  }

  void _validate() {
    isValid.value = fromNameCtrl.text.trim().isNotEmpty &&
        fromEmailCtrl.text.trim().isNotEmpty &&
        toEmailCtrl.text.trim().isNotEmpty &&
        subjectCtrl.text.trim().isNotEmpty &&
        bodyCtrl.text.trim().isNotEmpty &&
        signatureCtrl.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
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

Future<void> _sendMail() async {
    try {
      // Prepare email data
      final toEmail = toEmailCtrl.text.trim();
      final subject = subjectCtrl.text.trim();

      // Build email body with all components
      final body =
          '''
${bodyCtrl.text.trim()}

${signatureCtrl.text.trim()}
''';

      // Create mailto URI
      final mailtoUri = Uri(
        scheme: 'mailto',
        path: toEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
          'cc': ccEmailCtrl.text.trim().isNotEmpty ? ccEmailCtrl.text.trim() : null,
          'bcc': bccEmailCtrl.text.trim().isNotEmpty ? bccEmailCtrl.text.trim() : null,
        }..removeWhere((key, value) => value == null || value.isEmpty),
      );

      // Check if can launch
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);

        // Save to sent mails after successful launch
        final sentMail = SentMailModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          templateId: widget.template.id,
          fromName: fromNameCtrl.text.trim(),
          fromEmail: fromEmailCtrl.text.trim(),
          toEmail: toEmailCtrl.text.trim(),
          ccEmail: ccEmailCtrl.text.trim(),
          bccEmail: bccEmailCtrl.text.trim(),
          subject: subjectCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          signature: signatureCtrl.text.trim(),
          sentAt: DateTime.now().millisecondsSinceEpoch,
        );

        await SentMailController.addSentMail(sentMail);

        Get.back(result: true);

        Get.snackbar(
          "Mail Prepared",
          "Email client opened. Your email has been saved to Sent Mails",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        );
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not open email client. Please check if you have an email app installed.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    final topOffset = MediaQuery.of(context).padding.top + 80;

    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: Material(
        color: AppColors.kAppBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              emailHeader(context, "Send Mail"),
              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kAppSecondary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("From Name *"),
                        const SizedBox(height: 5),
                        inputBox(controller: fromNameCtrl, hint: "HR Department"),

                        const SizedBox(height: 16),
                        _label("From Email *"),
                        const SizedBox(height: 5),
                        inputBox(controller: fromEmailCtrl, hint: "hr@company.com"),

                        const SizedBox(height: 16),
                        _label("To *"),
                        const SizedBox(height: 5),
                        inputBox(controller: toEmailCtrl, hint: "client@email.com"),

                        const SizedBox(height: 16),
                        _label("CC"),
                        const SizedBox(height: 5),
                        inputBox(controller: ccEmailCtrl, hint: "manager@company.com"),

                        const SizedBox(height: 16),
                        _label("BCC"),
                        const SizedBox(height: 5),
                        inputBox(controller: bccEmailCtrl, hint: "audit@company.com"),

                        const SizedBox(height: 16),
                        _label("Subject *"),
                        const SizedBox(height: 5),
                        inputBox(controller: subjectCtrl, hint: "Enter subject"),

                        const SizedBox(height: 16),
                        _label("Body *"),
                        const SizedBox(height: 5),
                        inputBox(
                          controller: bodyCtrl,
                          hint: "Write mail body",
                          height: 140,
                          maxLines: 6,
                        ),

                        const SizedBox(height: 16),
                        _label("Signature *"),
                        const SizedBox(height: 5),
                        inputBox(
                          controller: signatureCtrl,
                          hint: "Regards,\nCompany Name",
                          height: 120,
                          maxLines: 5,
                        ),

                        const SizedBox(height: 20),

                        Obx(
                              () => IgnorePointer(
                            ignoring: !isValid.value,
                            child: Opacity(
                              opacity: isValid.value ? 1 : 0.5,
                              child: SizedBox(
                                width: double.infinity,
                                child: gradientButton("Send", _sendMail),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 13,
    ),
  );
}

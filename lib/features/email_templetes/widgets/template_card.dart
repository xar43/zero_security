// import 'package:flutter/material.dart';
// import '../../../config/colors/app_colors.dart';
// import '../models/email_template_model.dart';
//
// class TemplateCard extends StatefulWidget {
//   final EmailTemplateModel template;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;
//
//   const TemplateCard({
//     super.key,
//     required this.template,
//     required this.onEdit,
//     required this.onDelete,
//   });
//
//   @override
//   State<TemplateCard> createState() => _TemplateCardState();
// }
//
// class _TemplateCardState extends State<TemplateCard> {
//   bool expanded = false;
//
//   Widget _row(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: SizedBox(
//         width: double.infinity,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "$label:",
//               style: TextStyle(
//                 color: AppColors.kAppSecondary,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.left,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value.isEmpty ? "-" : value,
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 13,
//               ),
//               textAlign: TextAlign.left,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// ✅ Mail Preview Widget
//   Widget _mailPreview() {
//     final t = widget.template;
//
//     final previewText = """
// From: ${t.fromName} <${t.fromEmail}>
// To: ${t.toEmail}${t.ccEmail.isNotEmpty ? "\nCC: ${t.ccEmail}" : ""}${t.bccEmail.isNotEmpty ? "\nBCC: ${t.bccEmail}" : ""}
// Subject: ${t.subject}
//
// ${t.body}
//
// ${t.signature}
// """;
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       margin: const EdgeInsets.only(top: 10),
//       decoration: BoxDecoration(
//         color: Colors.black.withValues(alpha: .35),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Colors.white.withValues(alpha: .10),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Mail Preview",
//             style: TextStyle(
//               color: AppColors.kAppSecondary,
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             previewText.trim(),
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 13,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: AppColors.kAppSecondary.withValues(alpha: .15),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         children: [
//           /// HEADER (TITLE + ACTIONS)
//           InkWell(
//             borderRadius: BorderRadius.circular(14),
//             onTap: () {
//               setState(() => expanded = !expanded);
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       widget.template.title,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//
//                   /// EDIT
//                   GestureDetector(
//                     onTap: widget.onEdit,
//                     child: const Padding(
//                       padding: EdgeInsets.all(6),
//                       child: Icon(Icons.edit, color: Colors.white70, size: 20),
//                     ),
//                   ),
//
//                   const SizedBox(width: 6),
//
//                   /// DELETE
//                   GestureDetector(
//                     onTap: widget.onDelete,
//                     child: const Padding(
//                       padding: EdgeInsets.all(6),
//                       child:
//                       Icon(Icons.delete, color: Colors.redAccent, size: 20),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           /// EXPANDED DETAILS
//           if (expanded)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // const SizedBox(height: 6),
//
//                     // _row("From Name", widget.template.fromName),
//                     // _row("From Email", widget.template.fromEmail),
//                     // _row("To", widget.template.toEmail),
//                     // _row("CC", widget.template.ccEmail),
//                     // _row("BCC", widget.template.bccEmail),
//                     // _row("Subject", widget.template.subject),
//                     // _row("Body", widget.template.body),
//                     // _row("Signature", widget.template.signature),
//                     //
//                     // const SizedBox(height: 8),
//
//                     _mailPreview(),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../../config/colors/app_colors.dart';
import '../models/email_template_model.dart';
import '../screens/send_mail_edit_sheet.dart';

class TemplateCard extends StatefulWidget {
  final EmailTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool expanded = false;

  /// ✅ Mail Preview Widget
  Widget _mailPreview() {
    final t = widget.template;

    final previewText = """
From: ${t.fromName} <${t.fromEmail}>
To: ${t.toEmail}${t.ccEmail.isNotEmpty ? "\nCC: ${t.ccEmail}" : ""}${t.bccEmail.isNotEmpty ? "\nBCC: ${t.bccEmail}" : ""}
Subject: ${t.subject}

${t.body}

${t.signature}
""";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mail Preview",
            style: TextStyle(
              color: AppColors.kAppSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            previewText.trim(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSendSheet() async {
    await showSendMailSheet(
      context,
      template: widget.template,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.kAppSecondary.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          /// HEADER (TITLE + ACTIONS)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => expanded = !expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.template.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  /// SEND
                  GestureDetector(
                    onTap: _openSendSheet,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.send, color: Colors.white70, size: 20),
                    ),
                  ),

                  const SizedBox(width: 6),

                  /// EDIT
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit, color: Colors.white70, size: 20),
                    ),
                  ),

                  const SizedBox(width: 6),

                  /// DELETE
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// EXPANDED DETAILS
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mailPreview(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

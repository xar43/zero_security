// import 'package:flutter/material.dart';
// import '../../../config/colors/app_colors.dart';
// import '../controller/announcement_controller.dart';
// import '../models/announcement_model.dart';
//
// Future<dynamic> showAddAnnouncementSheet(BuildContext context) {
//   return showGeneralDialog(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: 'Add Announcement',
//     barrierColor: Colors.black54,
//     transitionDuration: const Duration(milliseconds: 280),
//     pageBuilder: (_, _, _) => const SizedBox(),
//     transitionBuilder: (_, animation, _, _) {
//       return SlideTransition(
//         position: Tween(begin: const Offset(0, 1), end: Offset.zero)
//             .animate(animation),
//         child: const AddAnnouncementSheet(),
//       );
//     },
//   );
// }
//
// class AddAnnouncementSheet extends StatefulWidget {
//   const AddAnnouncementSheet({super.key});
//
//   @override
//   State<AddAnnouncementSheet> createState() => _AddAnnouncementSheetState();
// }
//
// class _AddAnnouncementSheetState extends State<AddAnnouncementSheet> {
//   late final TextEditingController descCtrl;
//   bool isValid = false;
//
//   @override
//   void initState() {
//     super.initState();
//     descCtrl = TextEditingController();
//     descCtrl.addListener(_validate);
//   }
//
//   void _validate() {
//     setState(() {
//       isValid = descCtrl.text.trim().isNotEmpty;
//     });
//   }
//
//   Future<void> _submit() async {
//     final text = descCtrl.text.trim();
//     if (text.isEmpty) return;
//
//     final announcement = AnnouncementModel(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       description: text,
//       createdAt: DateTime.now(),
//     );
//
//     await AnnouncementController.addAnnouncement(announcement);
//
//     Navigator.pop(context, true);
//   }
//
//   @override
//   void dispose() {
//     descCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final todayText =
//         "TODAY   ${now.day}/${now.month}/${now.year} | ${TimeOfDay.now().format(context)}";
//
//     final topOffset = MediaQuery.of(context).padding.top + 80;
//
//     return Padding(
//       padding: EdgeInsets.only(top: topOffset),
//       child: Material(
//         color: AppColors.kAppBackground,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               _header(context, "Announcements"),
//               const SizedBox(height: 12),
//
//               /// TODAY BAR
//               Container(
//                 width: double.infinity,
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: AppColors.kAppSecondary.withValues(alpha: .25),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   todayText,
//                   style: const TextStyle(color: Colors.white70, fontSize: 12),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: AppColors.kAppSecondary.withValues(alpha: .15),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       RichText(
//                         text: const TextSpan(
//                           text: "Announcement Description ",
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 13,
//                           ),
//                           children: [
//                             TextSpan(
//                               text: "*",
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//
//                       /// INPUT FIELD (EXACT LIKE NOTE)
//                       _inputBox(
//                         controller: descCtrl,
//                         hint: "Write announcement...",
//                         height: 120,
//                         maxLines: 5,
//                       ),
//
//                       const Spacer(),
//
//                       /// SUBMIT BUTTON (EXACT LIKE NOTE)
//                       IgnorePointer(
//                         ignoring: !isValid,
//                         child: Opacity(
//                           opacity: isValid ? 1 : 0.5,
//                           child: SizedBox(
//                             width: double.infinity,
//                             child: _gradientButton(
//                               "Submit",
//                                   () async {
//                                 await _submit();
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// HEADER EXACT LIKE NOTE
//   Widget _header(BuildContext context, String title) => Row(
//     children: [
//       Expanded(
//         child: Text(
//           title,
//           style: const TextStyle(color: Colors.white, fontSize: 18),
//         ),
//       ),
//       IconButton(
//         icon: const Icon(Icons.close, color: Colors.white),
//         onPressed: () => Navigator.pop(context),
//       ),
//     ],
//   );
//
//   /// INPUT BOX EXACT LIKE NOTE
//   Widget _inputBox({
//     required TextEditingController controller,
//     required String hint,
//     double height = 45,
//     int maxLines = 1,
//   }) =>
//       SizedBox(
//         height: height,
//         width: double.infinity,
//         child: TextField(
//           controller: controller,
//           maxLines: maxLines,
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(color: Colors.white54),
//             filled: true,
//             fillColor: AppColors.kAppSecondary.withValues(alpha: .18),
//             contentPadding: const EdgeInsets.all(12),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       );
//
//   /// BUTTON EXACT LIKE NOTE
//   Widget _gradientButton(String text, VoidCallback onTap) => Container(
//     height: 46,
//     decoration: BoxDecoration(
//       gradient: AppColors.primaryGradient,
//       borderRadius: BorderRadius.circular(10),
//     ),
//     child: TextButton(
//       onPressed: onTap,
//       child: Text(text, style: const TextStyle(color: Colors.white)),
//     ),
//   );
// }

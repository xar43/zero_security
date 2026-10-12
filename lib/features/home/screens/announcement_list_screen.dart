import 'package:flutter/material.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';

import '../../../config/colors/app_colors.dart';
import '../controller/announcement_controller.dart';
import '../models/announcement_model.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<AnnouncementModel> announcements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    setState(() => loading = true);

    announcements = await AnnouncementController.getAnnouncements();

    /// IF EMPTY → SHOW DUMMY ANNOUNCEMENTS
    if (announcements.isEmpty) {
      announcements = [
        AnnouncementModel(
          id: "1",
          description: "Meeting scheduled at 3:00 PM today. Please be on time.",
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AnnouncementModel(
          id: "2",
          description: "New sales targets have been updated for this month.",
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AnnouncementModel(
          id: "3",
          description: "Reminder: Submit your daily activity report before 6 PM.",
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        AnnouncementModel(
          id: "4",
          description: "System maintenance will happen tonight from 12 AM to 2 AM.",
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        AnnouncementModel(
          id: "5",
          description: "Client follow-up training session is scheduled for Friday.",
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
    }

    setState(() => loading = false);
  }


  // void _confirmDelete(String id) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       backgroundColor: AppColors.kAppBackground,
  //       title: const Text(
  //         "Delete Announcement",
  //         style: TextStyle(color: Colors.white),
  //       ),
  //       content: const Text(
  //         "Are you sure you want to delete this announcement?",
  //         style: TextStyle(color: Colors.white70),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             await AnnouncementController.deleteAnnouncement(id);
  //             loadAnnouncements();
  //           },
  //           child: const Text(
  //             "Delete",
  //             style: TextStyle(color: Colors.red),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.kAppBackground,
      appBar: AppBar(
        title: const Text("Announcements"),
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppColors.kAppSecondary,
      //   onPressed: () async {
      //     final result = await showAddAnnouncementSheet(context);
      //     if (result == true) {
      //       loadAnnouncements();
      //     }
      //   },
      //   child: const Icon(Icons.add, color: Colors.black),
      // ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A).withValues(alpha: .92),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : announcements.isEmpty
              ? const Center(
            child: Text(
              "No Announcements Found",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : RefreshIndicator(
            onRefresh: loadAnnouncements,
            child: ListView.builder(
              itemCount: announcements.length,
              itemBuilder: (_, index) {
                final item = announcements[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(item.createdAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(width: 8),
                      // IconButton(
                      //   onPressed: () =>
                      //       _confirmDelete(item.id),
                      //   icon: const Icon(
                      //     Icons.delete_outline,
                      //     color: Colors.redAccent,
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

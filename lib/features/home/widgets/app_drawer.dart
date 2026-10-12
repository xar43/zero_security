import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/constants/app_assets.dart';
import 'package:toggle_timer/core/common_widgets/custom_image_widget.dart';
import 'package:toggle_timer/features/home/screens/home_screen.dart';

import '../../email_templetes/screens/email_template_list_screen.dart';
import '../../email_templetes/screens/sent_mail_list_screen.dart';
import '../../notes/controller/note_controller.dart';
import '../../notes/screens/note_history_screen.dart';
import '../../sales/screens/sales_dashboard_screen.dart';
import '../../sales/screens/tasks_screen.dart';
import '../controller/drawer_controller.dart';
import '../../../config/local/local_storage_services.dart';
import '../../auth/screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});


  static final AppDrawerController controller = Get.put(AppDrawerController());

  void _ensureNotesController() {
    if (!Get.isRegistered<NotesController>()) {
      Get.put(NotesController());
    }
  }



  @override
  Widget build(BuildContext context) => Drawer(
    child: ListView(
      children: [
        Transform.translate(
          offset: Offset(-60, 0),
          child: Transform.scale(scale: .6, child: CustomImageWidget(imageUrl: AppAssets.icon)),
        ),
        _buildHeader(title: "MENU"),
        _buildItem(
          title: "Dashboard",
          icon: Icons.home_outlined,
          isActive: controller.selectedIndex == "Dashboard",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Dashboard") return;

            Navigator.pop(context);
            Get.to(() => const HomeScreen());
            controller.setSelectedIndex("Dashboard");
          },
        ),
        _buildItem(
          title: "Assigned Tasks",
          icon: Icons.task_outlined,
          isActive: controller.selectedIndex == "Assigned Tasks",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Assigned Tasks") return;
            
            controller.setSelectedIndex("Assigned Tasks");
            Navigator.pop(context);
            
            Get.to(() => const TasksScreen(lead: null));
          },
        ),
        _buildItem(
          title: "Sales Dashboard",
          icon: Icons.home_work_outlined,
          isActive: controller.selectedIndex == "Sales Dashboard",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Sales Dashboard") return;

            controller.setSelectedIndex("Sales Dashboard");
            Navigator.pop(context);
            Get.to(() => const SalesDashboardScreen());
          },
        ),
        _buildItem(
          title: "Notes",
          icon: Icons.notes,
          isActive: controller.selectedIndex == "Notes",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Notes") return;

            _ensureNotesController();
            controller.setSelectedIndex("Notes");
            Navigator.pop(context);

            Get.to(() => const NotesListScreen());
          },
        ),

        _buildItem(
          title: "Email Templates",
          icon: Icons.email_outlined,
          isActive: controller.selectedIndex == "Email Templates",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Email Templates") return;

            controller.setSelectedIndex("Email Templates");
            Navigator.pop(context);

            Get.to(() => const EmailTemplateListScreen());
          },
        ),

        _buildItem(
          title: "Sent Mails",
          icon: Icons.send_outlined,
          isActive: controller.selectedIndex == "Sent Mails",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Sent Mails") return;

            controller.setSelectedIndex("Sent Mails");
            Navigator.pop(context);

            Get.to(() => const SentMailListScreen());
          },
        ),


        _buildHeader(title: "OTHERS"),
        _buildItem(
          title: "MOM",
          icon: Icons.description,
          isActive: controller.selectedIndex == "MOM",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "MOM") return;

            controller.setSelectedIndex("MOM");
          },
        ),
        _buildItem(
          title: "Alert Messages",
          icon: Icons.notification_important_outlined,
          isActive: controller.selectedIndex == "Alert Messages",
          hasSubmenu: false,
          onTap: () {
            if (controller.selectedIndex == "Alert Messages") return;

            controller.setSelectedIndex("Alert Messages");
          },
        ),
        _buildItem(
          title: "Settings",
          icon: Icons.settings_outlined,
          isActive: controller.selectedIndex == "Settings",
          hasSubmenu: true,
          onTap: () {
            if (controller.selectedIndex == "Settings") return;

            controller.setSelectedIndex("Settings");
          },
        ),
        const Divider(color: Colors.white24, height: 32),
        _buildItem(
          title: "Logout",
          icon: Icons.logout,
          isActive: false,
          hasSubmenu: false,
          onTap: () async {
            Navigator.pop(context); // Drawer band karo
            await LocalStorageServices.clearAll(); // Saara saved data clear karo
            Get.offAll(() => const LoginScreen()); // Login screen par bhejo
          },
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  // Widget _buildSubItem({
  //   required String title,
  //   required VoidCallback onTap,
  // }) =>
  //     Padding(
  //       padding: const EdgeInsets.only(left: 56),
  //       child: ListTile(
  //         dense: true,
  //         title: Text(
  //           title,
  //           style: const TextStyle( color: Colors.white,),
  //         ),
  //         onTap: onTap,
  //       ),
  //     );

  Widget _buildHeader({required String title}) => Padding(
    padding: const EdgeInsets.only(left: 24.0, bottom: 12.0, top: 12.0),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2),
    ),
  );

  Widget _buildItem({
    required String title,
    required IconData icon,
    required bool isActive,
    bool hasSubmenu = false,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: isActive ? AppColors.kAppSecondary : Colors.transparent,
      borderRadius: BorderRadius.circular(4), // Slightly rounded corners like image (optional)
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              if (hasSubmenu) const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

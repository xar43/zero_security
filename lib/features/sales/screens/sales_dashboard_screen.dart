import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';
import 'package:toggle_timer/features/sales/models/lead_model.dart';
import 'package:toggle_timer/features/sales/screens/add_follow_up_sheet.dart';

import '../../../core/helper/app_helper.dart';
import '../../../core/utils/app_utils.dart';
import '../../../main.dart';
import '../../home/widgets/app_drawer.dart';
import 'add_lead_screen.dart';
import 'lead_details_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {



final _scaffoldKey = GlobalKey<ScaffoldState>();
 



  void _handleMenuSelection(String value, LeadModel lead, BuildContext context) {
    switch (value) {
      case 'Add follow up':
        showModalBottomSheet(
          context: context,
          builder: (context) => AddFollowUpSheet(lead: lead),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
        break;
      case 'Edit':
        Get.to(() => AddLeadScreen(lead: lead));
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffoldKey,
    drawer: AppDrawer(),
    appBar: AppBar(
      title: const Text('Sales Dashboard'),
      flexibleSpace: AppUtils.gradientFlexibleSpace(),
      leading: AppHelper.buildDrawerButton(_scaffoldKey),
    ),
    body: Container(
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: RefreshIndicator(
        onRefresh: () async => leadController.fetchLeads(),
        child: ListView(
          children: [
            // --- Header Section ---
            const DashboardHeader().paddingAll(16),

            // --- Stats Row ---
            // Using SingleChildScrollView to prevent overflow on smaller screens
            Row(
                children: const [
                  StatCard(
                    value: "24",
                    title: "Total Leads",
                    subtitle: "January, 2025",
                    trend: "+2%",
                    icon: Icons.person,
                  ),
                SizedBox(width: 8),
                  StatCard(
                    value: "10%",
                    title: "Conversion Rate",
                    subtitle: "January, 2025",
                    trend: "+2%",
                    icon: Icons.check_circle_outline,
                  ),
                SizedBox(width: 8),
                  StatCard(
                    value: "1000",
                    title: "Revenue",
                    subtitle: "January, 2025",
                    trend: "", // Example of optional trend
                    icon: Icons.attach_money,
                  ),
              ],
            ).paddingSymmetric(horizontal: 16),
            SizedBox(height: 16),
            Obx(
              () => Container(
                width: context.width,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kAppBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text("Leads List", style: AppTypography.style20SemiBold),
                        Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.kAppWhite,
                            backgroundColor: AppColors.kAppWhite.withValues(alpha: 0.1),
                          ),
                          onPressed: () => Get.to(() => const AddLeadScreen()),
                          child: Text("Add Lead"),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    leadController.leads.isEmpty && !leadController.isLoading
                        ? Text("No Leads Yet", style: AppTypography.style20SemiBold).paddingSymmetric(vertical: 100)
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final lead = leadController.leads.isEmpty
                                  ? LeadModel.fromMap({})
                                  : leadController.leads[index];
                              return Skeletonizer(
                                enabled: leadController.isLoading,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 69, 69, 69),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    onTap: () => Get.to(() => LeadDetailsScreen(lead: lead)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(lead.name, style: AppTypography.style16SemiBold)),
                                        Text("Contact: ${lead.contactInfo}", style: AppTypography.style14Regular),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Expanded(child: Text(lead.address, style: AppTypography.style14Regular)),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.white),
                                          color: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: Colors.grey.shade700, width: 1),
                                          ),
                                          onSelected: (value) => _handleMenuSelection(value, lead, context),
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'Add follow up',
                                              textStyle: TextStyle(color: Colors.white),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.add_comment, color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text('Add follow up', style: AppTypography.style16Regular),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Edit',
                                              textStyle: TextStyle(color: Colors.white),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text('Edit', style: AppTypography.style16Regular),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemCount: leadController.leads.length,
                          ),
                    SizedBox(height: context.height * 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- Component: Header ---
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome,", style: AppTypography.style18Regular.copyWith(color: Colors.black)),
          Text(
            "Tushar negi",
            style: AppTypography.style32SemiBold.copyWith(
              color: Colors.black,
              height: 1.1, // Tighter line height
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("Thu, Jan 9, 2025", style: AppTypography.style18SemiBold.copyWith(color: Colors.black)),
          const SizedBox(height: 4),
          Text("12:00PM", style: AppTypography.style16Regular.copyWith(color: Colors.black)),
        ],
      ),
    ],
  );
}

// --- Component: Reusable Stat Card ---
class StatCard extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final String trend;
  final IconData icon;

  const StatCard({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    this.trend = "",
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55), // Semi-transparent card bg
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circle with Value
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Text(value, style: AppTypography.style20SemiBold)),
          ),

          // Bottom Info Section
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.style14SemiBold,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTypography.style10Regular.copyWith(color: Colors.white70),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trend.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.north_east, color: Colors.greenAccent, size: 10),
                      Text(trend, style: AppTypography.style10SemiBold.copyWith(color: Colors.greenAccent)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

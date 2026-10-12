import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/features/sales/models/lead_model.dart';

import '../../../core/common_widgets/custom_app_button.dart';
import '../controller/location_controller.dart';

class CurrentLocationScreen extends StatelessWidget {
  CurrentLocationScreen({super.key, required this.leadModel});
  final LeadModel leadModel;
  final LocationController _controller = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Location'), flexibleSpace: AppUtils.gradientFlexibleSpace()),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Tracking Control Card
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.kAppCardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _controller.isTracking.value
                      ? Colors.red.withOpacity(0.3)
                      : AppColors.greenColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _controller.isTracking.value
                            ? Icons.fiber_manual_record_rounded
                            : Icons.pause_circle_outline_rounded,
                        color: _controller.isTracking.value ? Colors.red : AppColors.greenColor,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _controller.isTracking.value ? 'Tracking Active' : 'Tracking Inactive',
                        style: AppTypography.style18SemiBold.copyWith(color: AppColors.kAppWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomAppButton(
                      text: _controller.isTracking.value ? "Stop Tracking" : "Start Tracking",
                      onPressed: () {
                        _controller.isTracking.value ? _controller.stopTracking() : _controller.startTracking();
                      },
                      borderRadius: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sessions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tracking History', style: AppTypography.style20Bold.copyWith(color: AppColors.kAppWhite)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.kAppCardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(
                  () => Text(
                    '${_controller.dailyLocationMap.length} sessions',
                    style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppWhite.withOpacity(0.7)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sessions List
          Obx(() {
            final sortedKeys = _controller.dailyLocationMap.keys.toList()..sort((a, b) => b.compareTo(a));

            if (sortedKeys.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 80, color: AppColors.kAppWhite.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "No tracking sessions yet",
                        style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Start tracking to see your location history",
                        style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite.withOpacity(0.3)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: sortedKeys.map((key) {
                final session = _controller.dailyLocationMap[key]!;
                final isActive = session.endTime.isEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.kAppCardColor.withOpacity(0.2), AppColors.kAppCardColor.withOpacity(0.05)],
                    ),
                    border: Border.all(
                      color: isActive ? AppColors.greenColor.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Session Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          color: isActive ? AppColors.greenBackgroundColor : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.greenColor.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isActive ? Icons.fiber_manual_record_rounded : Icons.history,
                                color: isActive ? AppColors.greenColor : Colors.white70,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(key, style: AppTypography.style16Bold.copyWith(color: AppColors.kAppWhite)),
                                  const SizedBox(height: 4),
                                  Text(
                                    isActive ? 'Active Session' : 'Completed',
                                    style: AppTypography.style12SemiBold.copyWith(
                                      color: isActive ? AppColors.greenColor : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${session.hourlyLocations.length} locations',
                                style: AppTypography.style12SemiBold.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Session Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Info
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoChip(
                                    icon: Icons.play_arrow_rounded,
                                    label: 'Start Time',
                                    value: session.startTime,
                                    color: Colors.green,
                                  ),
                                ),

                                if (session.endTime.isNotEmpty) SizedBox(width: 10),
                                if (session.endTime.isNotEmpty)
                                  Expanded(
                                    child: _buildInfoChip(
                                      icon: Icons.stop_rounded,
                                      label: 'End Time',
                                      value: session.endTime,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Start Location
                            _buildLocationSection(
                              title: 'Start Location',
                              location: session.startLocation,
                              icon: Icons.flag_circle_rounded,
                              color: Colors.green,
                            ),

                            const SizedBox(height: 16),

                            // Tracked Locations
                            if (session.hourlyLocations.isNotEmpty) ...[
                              Text(
                                'Tracked Locations',
                                style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppWhite),
                              ),
                              const SizedBox(height: 12),
                              ...session.hourlyLocations.map((loc) => _buildLocationItem(loc)),
                              const SizedBox(height: 16),
                            ],

                            // End Location
                            if (session.endLocation.isNotEmpty)
                              _buildLocationSection(
                                title: 'Stop Location',
                                location: session.endLocation,
                                icon: Icons.location_on_rounded,
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
  

  Widget _buildInfoChip({required IconData icon, required String label, required String value, required Color color}) =>
      Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.style10Regular.copyWith(color: Colors.white70)),
              Text(value, style: AppTypography.style12SemiBold.copyWith(color: AppColors.kAppWhite)),
            ],
          ),
        ],
      ),
    );
  

  Widget _buildLocationSection({
    required String title,
    required String location,
    required IconData icon,
    required Color color,
  }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.style14SemiBold.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(location, style: AppTypography.style14Regular.copyWith(color: AppColors.kAppWhite)),
              ),
            ],
          ),
        ),
      ],
  );
  

  Widget _buildLocationItem(String location) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.location_on, size: 16, color: AppColors.greenColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(location, style: AppTypography.style14Regular.copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  
}

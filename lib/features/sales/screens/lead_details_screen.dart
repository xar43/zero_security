import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/features/sales/screens/calls_screen.dart';
import 'package:toggle_timer/features/sales/screens/recording_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/colors/app_colors.dart';
import '../../../config/typography/app_typography.dart';
import '../../../core/common_widgets/custom_text_field.dart';
import '../models/lead_model.dart';
import 'add_follow_up_sheet.dart'; // Import the new follow-up sheet
import 'add_images_screen.dart';
import 'add_lead_screen.dart';
import 'current_location_screen.dart';

class LeadDetailsScreen extends StatefulWidget {
  final LeadModel lead;

  const LeadDetailsScreen({super.key, required this.lead});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  late LeadModel _lead;
  bool _isLoading = false;
  bool _showCompletedFollowUps = false; // Toggle to show/hide completed follow-ups

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
  }


Future<void> _makePhoneCall() async {
    final phoneNumber = _lead.contactInfo.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phoneNumber.isNotEmpty) {
      final url = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      
        // Add activity log for phone call
        setState(() => _isLoading = true);
        try {
          final updatedLead = _lead.addActivity('Phone Call', 'Made a phone call to $_lead.contactInfo');
          await updatedLead.save();
          setState(() => _lead = updatedLead);
        } catch (e) {
          debugPrint('Failed to add phone call activity log: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        AppPrompts.showError(message: 'Could not launch phone dialer');
      }
    }
  }

Future<void> _sendWhatsApp() async {
    final phoneNumber = _lead.contactInfo.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phoneNumber.isNotEmpty) {
      final url = Uri.parse('https://wa.me/$phoneNumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      
        // Add activity log for WhatsApp message
        setState(() => _isLoading = true);
        try {
          final updatedLead = _lead.addActivity('WhatsApp', 'Sent WhatsApp message to $_lead.contactInfo');
          await updatedLead.save();
          setState(() => _lead = updatedLead);
        } catch (e) {
          debugPrint('Failed to add WhatsApp activity log: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        AppPrompts.showError(message: 'Could not launch WhatsApp');
      }
    }
  }

  Future<void> _addActivityLog() async {
    final descriptionController = TextEditingController();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(
          'Add Activity Log',
          style: AppTypography.style18SemiBold.copyWith(color: AppColors.kAppOnBackground),
        ),
        backgroundColor: AppColors.kAppBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: descriptionController,
              headingLabelText: 'Description',
              isRequired: true,
              hintText: 'Enter activity description...',
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: descriptionController.text.trim()),
            child: Text('Save', style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppWhite)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final updatedLead = _lead.addActivity('Manual Entry', result);
        await updatedLead.save();
        setState(() => _lead = updatedLead);
        AppPrompts.showSuccess(message: 'Activity log added successfully');
      } catch (e) {
        AppPrompts.showError(message: 'Failed to add activity: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewFollowUp() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFollowUpSheet(
        lead: _lead,
        onFollowUpAdded: (updatedLead) async {
          setState(() {
            _lead = updatedLead;
          });
        },
      ),
    );
  }

  Future<void> _editFollowUp(FollowUp followUp) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFollowUpSheet(
        lead: _lead,
        followUpToEdit: followUp,
        onFollowUpAdded: (updatedLead) async {
          setState(() {
            _lead = updatedLead;
          });
        },
      ),
    );
  }

  Future<void> _markFollowUpComplete(FollowUp followUp) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Mark Follow-up Complete',
          style: AppTypography.style18SemiBold.copyWith(color: AppColors.kAppOnBackground),
        ),
        backgroundColor: AppColors.kAppBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Are you sure you want to mark this follow-up as complete?',
          style: AppTypography.style16Regular.copyWith(color: AppColors.kAppOnBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Complete', style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppWhite)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final updatedLead = _lead.completeFollowUp(followUp.id, 'Marked as completed');

        await updatedLead.save();
        setState(() {
          _lead = updatedLead;
        });
        AppPrompts.showSuccess(message: 'Follow-up marked as complete');
      } catch (e) {
        AppPrompts.showError(message: 'Failed to update follow-up: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFollowUp(FollowUp followUp) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Delete Follow-up',
          style: AppTypography.style18SemiBold.copyWith(color: AppColors.kAppOnBackground),
        ),
        backgroundColor: AppColors.kAppBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Are you sure you want to delete this follow-up?',
          style: AppTypography.style16Regular.copyWith(color: AppColors.kAppOnBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppError)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        // Remove follow-up from list
        final updatedFollowUps = _lead.followUps.where((f) => f.id != followUp.id).toList();
        final updatedLead = _lead.copyWith(followUps: updatedFollowUps);

        // Add activity log
        final leadWithActivity = updatedLead.addActivity(
          'Follow-up Deleted',
          'Deleted follow-up: ${followUp.scheduledDate}',
        );

        await leadWithActivity.save();
        setState(() {
          _lead = leadWithActivity;
        });
        AppPrompts.showSuccess(message: 'Follow-up deleted successfully');
      } catch (e) {
        AppPrompts.showError(message: 'Failed to delete follow-up: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareLead() async {
    final followUpInfo = _lead.nextFollowUp != null
        ? 'Next Follow Up: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lead.nextFollowUp!.scheduledDate!)} (${_lead.nextFollowUp!.type.name})'
        : 'No upcoming follow-ups';
    
    final shareText =
        '''
Lead: ${_lead.name}
Contact: ${_lead.contactInfo}
${_lead.companyName != null ? 'Company: ${_lead.companyName!}' : ''}
$followUpInfo
${_lead.notes != null ? 'Notes: ${_lead.notes!}' : ''}
Total Follow-ups: ${_lead.followUps.length}
Pending Follow-ups: ${_lead.followUps.where((f) => f.status == FollowUpStatus.pending).length}
Completed Follow-ups: ${_lead.followUps.where((f) => f.status == FollowUpStatus.completed).length}
''';

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _viewVisitingCard() async {
    if (_lead.visitingCardImagePath != null && File(_lead.visitingCardImagePath!).existsSync()) {
      await Get.to(
        () => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5.0,
              child: Image.file(File(_lead.visitingCardImagePath!), fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }
  }

  IconData _getFollowUpIcon(FollowUpType type) {
    switch (type) {
      case FollowUpType.call:
        return Icons.phone;
      case FollowUpType.email:
        return Icons.email;
      case FollowUpType.meeting:
        return Icons.people;
      case FollowUpType.other:
        return Icons.more_horiz;
    }
  }

  Color _getFollowUpStatusColor(FollowUpStatus status) {
    switch (status) {
      case FollowUpStatus.pending:
        return AppColors.kAppPrimary;
      case FollowUpStatus.completed:
        return AppColors.greenColor;
      case FollowUpStatus.cancelled:
        return AppColors.kAppError;
    }
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppPrompts.showError(message: 'Location permission is required');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      AppPrompts.showError(message: 'Please enable location permission in app settings');
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        String locationStr = '';
        bool hasPermission = await _ensureLocationPermission();
        if (hasPermission) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
          try {
             List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
             if (placemarks.isNotEmpty) {
               Placemark place = placemarks[0];
               locationStr = '${place.street ?? ""}, ${place.locality ?? ""}'.replaceAll(RegExp(r'^, |,$'), '').trim();
               if (locationStr == ',') locationStr = 'Unknown Location';
             }
          } catch (e) {
             locationStr = '${position.latitude}, ${position.longitude}';
          }
        } catch (e) {
          locationStr = 'Location unavailable';
        }
        } else {
          locationStr = 'Location permission denied';
        }

        final savedString = locationStr.isNotEmpty ? '${pickedFile.path}|$locationStr' : pickedFile.path;

        final updatedDocumentPaths = List<String>.from(_lead.documentImagePaths)..add(savedString);
        final updatedLead = _lead.copyWith(documentImagePaths: updatedDocumentPaths);
        await updatedLead.save();
        setState(() {
          _lead = updatedLead;
          _isLoading = false;
        });
        AppPrompts.showSuccess(message: 'Image and location added successfully');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppPrompts.showError(message: 'Error picking image: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'less than a minute';
    }
  }

  List<FollowUp> _getPendingFollowUps() =>
      _lead.followUps
        .where((followUp) => followUp.status == FollowUpStatus.pending)
        .where((followUp) => followUp.scheduledDate != null)
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
  

  List<FollowUp> _getCompletedFollowUps() =>
      _lead.followUps.where((followUp) => followUp.status == FollowUpStatus.completed).toList()
      ..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));
  
  RxList<IconData> icons = <IconData>[Icons.music_note, Icons.location_on_outlined, Icons.camera_alt, Icons.image].obs;

  RxList<String> title = <String>['Meeting Recording', 'Current Location', 'Camera', "Add Image's"].obs;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lead Details'), flexibleSpace: AppUtils.gradientFlexibleSpace()),
    body: Skeletonizer(
      enabled: _isLoading,
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildNextFollowUpCard(),
          _buildFollowUpsList(),
          _buildInfoCard('Notes', _lead.notes),
          if (_lead.proposalLink != null)
            _buildInfoCard(
              'Proposal Link',
              _lead.proposalLink,
              trailing: IconButton(
                onPressed: () async {
                  final url = Uri.parse(_lead.proposalLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    AppPrompts.showError(message: 'Could not open link');
                  }
                },
                icon: Icon(Icons.open_in_new, color: AppColors.kAppPrimary, size: 20),
              ),
            ),
          _buildAttachmentsCard(),
          GridView.builder(
            itemCount: title.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(), // Prevent internal scrolling
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  switch (index) {
                    case 0:
                      Get.to(() => RecordingScreen(lead: _lead));
                      break;
                    case 1:
                      Get.to(() => CurrentLocationScreen(leadModel: _lead));
                      break;
                    case 2:
                      _pickImageFromCamera();
                      break;
                    case 3:
                      Get.to(() => AddImagesScreen(lead: _lead));
                      break;
                    default:
                      break;
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromARGB(255, 69, 69, 69),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.kAppBlack,
                        child: Icon(icons[index], color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(title[index], style: AppTypography.style14Bold, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildActivityLog(),
          SizedBox(height: 150)
        ],
      ),
    ),
    floatingActionButton: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: _addNewFollowUp,
          backgroundColor: AppColors.kAppPrimary,
          child: const Icon(Icons.add_comment, color: Colors.white),
        ),
        SizedBox(width: 10),
        FloatingActionButton(
          onPressed: () => Get.to(() => CallsScreen(phone: _lead.contactInfo)),
          backgroundColor: AppColors.kAppPrimary,
          child: const Icon(Icons.phone_callback, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lead.name, style: AppTypography.style24Bold.copyWith(color: AppColors.kAppOnBackground)),
                    if (_lead.companyName != null)
                      Text(_lead.companyName!, style: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.kAppOnBackground),
                color: AppColors.kAppBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.kAppGrey.withValues(alpha: 0.3)),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Get.to(() => AddLeadScreen(lead: _lead));
                      break;
                    case 'delete':
                      AppPrompts.showConfirmation(
                        context: context,
                        title: "Delete Lead",
                        message: "Are you sure you want to delete ${_lead.name}? This action cannot be undone.",
                        onConfirm: () async {
                          setState(() => _isLoading = true);
                          try {
                            await _lead.delete();
                            AppPrompts.showSuccess(message: 'Lead deleted successfully');
                            Get.back();
                          } catch (e) {
                            AppPrompts.showError(message: 'Failed to delete lead: $e');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                      );
                      break;
                    case 'share':
                      _shareLead();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppColors.kAppOnBackground, size: 20),
                        const SizedBox(width: 12),
                        Text('Edit', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppOnBackground)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: AppColors.kAppOnBackground, size: 20),
                        const SizedBox(width: 12),
                        Text('Share', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppOnBackground)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outlined, color: AppColors.kAppError, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppError)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppOnBackground),
                    ),
                    const SizedBox(height: 4),
                    Text(_lead.contactInfo, style: AppTypography.style16Regular),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _makePhoneCall,
                    icon: Icon(Icons.phone, color: AppColors.greenColor),
                    style: IconButton.styleFrom(backgroundColor: AppColors.greenBackgroundColor),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendWhatsApp,
                    icon: Icon(Icons.chat, color: AppColors.greenColor),
                    style: IconButton.styleFrom(backgroundColor: AppColors.greenBackgroundColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String? value, {Widget? trailing}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppOnBackground)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.style16Regular.copyWith(color: AppColors.kAppOnBackground)),
        ],
      ),
    );
  }

  Widget _buildNextFollowUpCard() {
    final nextFollowUp = _lead.nextFollowUp;

    if (nextFollowUp == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.kAppGrey, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No Upcoming Follow-ups',
                  style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addNewFollowUp,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Follow-up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kAppPrimary,
                foregroundColor: AppColors.kAppWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final isOverdue = nextFollowUp.scheduledDate!.isBefore(DateTime.now());
    final timeDifference = nextFollowUp.scheduledDate!.difference(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.kAppBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverdue ? AppColors.kAppError : AppColors.kAppWhite, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: isOverdue ? AppColors.kAppError : AppColors.greenColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next Follow Up',
                  style: AppTypography.style16SemiBold.copyWith(
                    color: isOverdue ? AppColors.kAppError : AppColors.kAppOnBackground,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  isOverdue ? 'OVERDUE' : 'UPCOMING',
                  style: AppTypography.style12SemiBold.copyWith(color: Colors.white),
                ),
                backgroundColor: isOverdue ? AppColors.kAppError : AppColors.kAppPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(nextFollowUp.scheduledDate!),
            style: AppTypography.style18Bold.copyWith(color: AppColors.kAppOnBackground),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(_getFollowUpIcon(nextFollowUp.type), color: AppColors.kAppWhite, size: 16),
                const SizedBox(width: 8),
                Text(
                  nextFollowUp.type.name.toUpperCase(), style: AppTypography.style14SemiBold),
              ],
            ),
          ),
          if (nextFollowUp.isReminderSet || nextFollowUp.isRepeat)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (nextFollowUp.isReminderSet)
                    Chip(
                      label: Text('REMINDER SET', style: AppTypography.style12SemiBold.copyWith(color: Colors.white)),
                      backgroundColor: AppColors.brownColor,
                    ),
                  if (nextFollowUp.isRepeat)
                    Chip(
                      label: Text('REPEAT', style: AppTypography.style12SemiBold.copyWith(color: Colors.white)),
                      backgroundColor: AppColors.kAppPrimary,
                    ),
                ],
              ),
            ),
          // Time indicator
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              isOverdue
                  ? 'Overdue by ${_formatDuration(timeDifference.abs())}'
                  : 'In ${_formatDuration(timeDifference)}',
              style: AppTypography.style14Regular.copyWith(color: isOverdue ? AppColors.kAppError : AppColors.kAppGrey),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markFollowUpComplete(nextFollowUp),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark Complete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenColor,
                      side: BorderSide(color: AppColors.greenColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editFollowUp(nextFollowUp),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kAppPrimary,
                      foregroundColor: AppColors.kAppWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpsList() {
    final pendingFollowUps = _getPendingFollowUps();
    final completedFollowUps = _getCompletedFollowUps();
    final hasPending = pendingFollowUps.length > 1; // More than just the next one
    final hasCompleted = completedFollowUps.isNotEmpty;

    if (!hasPending && !hasCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('All Follow-ups', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppOnBackground)),
              const Spacer(),
              if (hasCompleted)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showCompletedFollowUps = !_showCompletedFollowUps;
                    });
                  },
                  child: Text(
                    _showCompletedFollowUps ? 'Hide Completed' : 'Show Completed',
                    style: AppTypography.style14Regular.copyWith(color: AppColors.kAppPrimary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Pending follow-ups (excluding the next one already shown)
          if (hasPending)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending (${pendingFollowUps.length - 1})',
                  style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppGrey),
                ),
                const SizedBox(height: 8),
                ...pendingFollowUps
                    .where((f) => f.id != _lead.nextFollowUp?.id)
                    .map((followUp) => _buildFollowUpItem(followUp)),
                const SizedBox(height: 16),
              ],
            ),

          // Completed follow-ups (conditionally shown)
          if (hasCompleted && _showCompletedFollowUps)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed (${completedFollowUps.length})',
                  style: AppTypography.style14SemiBold.copyWith(color: AppColors.kAppGrey),
                ),
                const SizedBox(height: 8),
                ...completedFollowUps.map((followUp) => _buildFollowUpItem(followUp)),
              ],
            ),

          // Empty state
          if (!hasPending && !_showCompletedFollowUps)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: AppColors.kAppGrey),
                  const SizedBox(height: 12),
                  Text('No other follow-ups', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowUpItem(FollowUp followUp) {
    final isCompleted = followUp.status == FollowUpStatus.completed;
    final isOverdue =
        !isCompleted && followUp.scheduledDate != null && followUp.scheduledDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 69, 69, 69),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? _getFollowUpStatusColor(FollowUpStatus.completed).withValues(alpha: 0.3)
              : isOverdue
              ? AppColors.kAppError.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (followUp.scheduledDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(followUp.scheduledDate!),
                      style: AppTypography.style12Regular,
                    ),
                  ],
                ),

              const Spacer(),
              Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  followUp.status.name.toUpperCase(),
                  style: AppTypography.style10SemiBold.copyWith(color: Colors.white),
                ),
                backgroundColor: _getFollowUpStatusColor(followUp.status),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              PopupMenuButton<String>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.kAppGrey),
                color: AppColors.kAppBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editFollowUp(followUp);
                      break;
                    case 'complete':
                      if (followUp.status != FollowUpStatus.completed) {
                        _markFollowUpComplete(followUp);
                      }
                      break;
                    case 'delete':
                      _deleteFollowUp(followUp);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.kAppOnBackground),
                        const SizedBox(width: 8),
                        Text('Edit', style: AppTypography.style12Regular.copyWith(color: AppColors.kAppOnBackground)),
                      ],
                    ),
                  ),
                  if (followUp.status != FollowUpStatus.completed)
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.greenColor),
                          const SizedBox(width: 8),
                          Text(
                            'Mark Complete',
                            style: AppTypography.style12Regular.copyWith(color: AppColors.greenColor),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.kAppError),
                        const SizedBox(width: 8),
                        Text('Delete', style: AppTypography.style12Regular.copyWith(color: AppColors.kAppError)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (followUp.notes != null && followUp.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Note: ${followUp.notes!}',
                style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    final hasVisitingCard = _lead.visitingCardImagePath != null;
    final hasDocuments = _lead.documentImagePaths.isNotEmpty;

    if (!hasVisitingCard && !hasDocuments) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attachments', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppOnBackground)),
          const SizedBox(height: 12),
          if (hasVisitingCard)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visiting Card', style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _viewVisitingCard,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.kAppScaffold),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_lead.visitingCardImagePath!), fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          if (hasDocuments)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documents (${_lead.documentImagePaths.length})',
                  style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => AddImagesScreen(lead: _lead)),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('View Attachments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kAppPrimary,
                      foregroundColor: AppColors.kAppWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivityLog() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.kAppBackground, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Activity History', style: AppTypography.style16SemiBold.copyWith(color: AppColors.kAppOnBackground)),
            const Spacer(),
            IconButton(
              onPressed: _addActivityLog,
              icon: Icon(Icons.add, color: AppColors.kAppPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lead.activityHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: AppColors.kAppGrey),
                const SizedBox(height: 16),
                Text('No activity yet', style: AppTypography.style16Regular.copyWith(color: AppColors.kAppGrey)),
                const SizedBox(height: 8),
                Text(
                  'Add your first activity log',
                  style: AppTypography.style14Regular.copyWith(color: AppColors.kAppGrey),
                ),
              ],
            ),
          )
        else
          Column(
            children: _lead.activityHistory
                .map(
                  (activity) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.kAppScaffold, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.kAppWhite.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(activity.activityType.toUpperCase(), style: AppTypography.style12SemiBold),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('hh:mm a').format(activity.timestamp),
                              style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity.description,
                          style: AppTypography.style14Regular.copyWith(color: AppColors.kAppOnBackground),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(activity.timestamp),
                          style: AppTypography.style12Regular.copyWith(color: AppColors.kAppGrey),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );
}


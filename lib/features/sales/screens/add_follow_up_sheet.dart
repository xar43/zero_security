import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/main.dart';

import '../../../config/notifications/app_notifications.dart';
import '../../../config/typography/app_typography.dart';
import '../../../core/common_widgets/custom_app_button.dart';
import '../models/lead_model.dart';

class AddFollowUpSheet extends StatefulWidget {
  const AddFollowUpSheet({super.key, required this.lead, this.followUpToEdit, this.onFollowUpAdded});

  final LeadModel lead;
  final FollowUp? followUpToEdit;
  final Function(LeadModel)? onFollowUpAdded;

  @override
  State<AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<AddFollowUpSheet> {
  bool _isLoading = false;
  
  final _notesController = TextEditingController();
  
  // State variables
  DateTime? _selectedFollowUpDate;
  FollowUpType _selectedFollowUpType = FollowUpType.call;
  FollowUpStatus _selectedFollowUpStatus = FollowUpStatus.pending;
  bool _isReminderSet = false;
  bool _isRepeatFollowUp = false;

  @override
  void initState() {
    super.initState();

    // If editing an existing follow-up, pre-fill the form
    if (widget.followUpToEdit != null) {
      final followUp = widget.followUpToEdit!;
      _notesController.text = followUp.notes ?? '';
      _selectedFollowUpDate = followUp.scheduledDate;
      _selectedFollowUpType = followUp.type;
      _selectedFollowUpStatus = followUp.status;
      _isReminderSet = followUp.isReminderSet;
      _isRepeatFollowUp = followUp.isRepeat;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectFollowUpDate() async {
    final now = DateTime.now();
    final initialDate = _selectedFollowUpDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initialDate));

      if (pickedTime != null) {
        setState(() {
          _selectedFollowUpDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveFollowUp() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final followUpId = widget.followUpToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final newFollowUp = FollowUp(
        id: followUpId,
        scheduledDate: _selectedFollowUpDate,
        type: _selectedFollowUpType,
        status: _selectedFollowUpStatus,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isReminderSet: _isReminderSet,
        isRepeat: _isRepeatFollowUp,
        createdAt: widget.followUpToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update lead with new/updated follow-up
      final updatedLead = widget.followUpToEdit != null
          ? widget.lead.updateFollowUp(followUpId, newFollowUp)
          : widget.lead.addFollowUp(newFollowUp);

      // --- NOTIFICATION SCHEDULING ---
      if (_isReminderSet && _selectedFollowUpDate != null) {
        // Cancel old notification if editing
        if (widget.followUpToEdit != null) {
          await AwesomeNotificationService.cancelNotification(followUpId);
        }

        // Schedule new notification
        await AwesomeNotificationService.scheduleFollowUpReminder(
          leadId: widget.lead.id!,
          leadName: widget.lead.name,
          followUpId: followUpId,
          scheduledDate: _selectedFollowUpDate!,
          followUpType: _selectedFollowUpType.name,
          notes: _notesController.text.trim(),
          reminderMinutes: 5, // Can be made configurable
        );
      }

      // --- RECURRING FOLLOW-UP ---
      if (_isRepeatFollowUp && _selectedFollowUpDate != null) {
        await AwesomeNotificationService.scheduleRecurringFollowUp(
          leadId: widget.lead.id!,
          leadName: widget.lead.name,
          followUpId: followUpId,
          startDate: _selectedFollowUpDate!,
          followUpType: _selectedFollowUpType.name,
          recurrencePattern: 'weekly', // Can be made configurable
          interval: 1,
        );
      }

      // Add activity log
      final activityType = widget.followUpToEdit != null ? 'Follow-up Updated' : 'Follow-up Added';
      final activityDescription = widget.followUpToEdit != null
          ? 'Updated follow-up: ${newFollowUp.scheduledDate}'
          : 'Added new follow-up: ${newFollowUp.scheduledDate}';

      final leadWithActivity = updatedLead.addActivity(activityType, activityDescription);

await leadController.addLead(leadWithActivity);

      // Call callback if provided
      widget.onFollowUpAdded?.call(leadWithActivity);

      if (mounted) {
        Navigator.pop(context);
        AppPrompts.showSuccess(
          message: widget.followUpToEdit != null ? 'Follow-up updated with reminder' : 'Follow-up added with reminder',
        );
      }
    } catch (e) {
      if (mounted) {
        AppPrompts.showError(message: 'Failed to save follow-up: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {

    if (_selectedFollowUpDate == null) {
      AppPrompts.showError(message: 'Please select a follow-up date');
      return false;
    }

    if (_selectedFollowUpStatus == FollowUpStatus.pending && _selectedFollowUpDate!.isBefore(DateTime.now())) {
      AppPrompts.showError(message: 'Pending follow-up cannot be in the past');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.followUpToEdit != null;

    return DraggableScrollableSheet(
      initialChildSize: isEditing ? .9 : .8,
      maxChildSize: .95,
      minChildSize: .3,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          controller: scrollController,
          children: [
            Row(
              children: [
                Text(
                  isEditing ? 'Edit Follow Up' : 'Add Follow Up',
                  style: AppTypography.style20Bold.copyWith(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
           
            // Date Picker
            Container(
              height: 57,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 69, 69, 69),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: TextButton(
                onPressed: _selectFollowUpDate,
                style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedFollowUpDate != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(_selectedFollowUpDate!)
                          : 'Schedule Follow Up',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Follow Up Type
            const Text('Follow Up Type', style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FollowUpType.values.map((type) {
                final isSelected = _selectedFollowUpType == type;
                return ChoiceChip(
                  label: Text(
                    type.name.toUpperCase(),
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade300),
                  ),
                  selected: isSelected,
                  selectedColor: const Color.fromARGB(255, 69, 69, 69),
                  backgroundColor: Colors.black,
                  side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade700, width: 1),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedFollowUpType = type;
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status (only for editing)
            if (isEditing) ...[
              const Text('Status', style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FollowUpStatus.values.map((status) {
                  final isSelected = _selectedFollowUpStatus == status;
                  return ChoiceChip(
                    label: Text(
                      status.name.toUpperCase(),
                      style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade300),
                    ),
                    selected: isSelected,
                    selectedColor: const Color.fromARGB(255, 69, 69, 69),
                    backgroundColor: Colors.black,
                    side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade700, width: 1),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedFollowUpStatus = status;
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Notes Field
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reminder Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 69, 69, 69),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Set Reminder', style: TextStyle(color: Colors.white)),
                subtitle: _isReminderSet
                    ? const Text(
                        'You will be notified before the follow-up',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : null,
                value: _isReminderSet,
                activeThumbColor: Colors.blue,
                onChanged: (value) => setState(() => _isReminderSet = value),
              ),
            ),
            const SizedBox(height: 8),
            
            // Repeat Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 69, 69, 69),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Repeat Follow Up', style: TextStyle(color: Colors.white)),
                subtitle: _isRepeatFollowUp
                    ? const Text(
                        'This follow-up will repeat periodically',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : null,
                value: _isRepeatFollowUp,
                activeThumbColor: Colors.blue,
                onChanged: (value) => setState(() => _isRepeatFollowUp = value),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            Center(
              child: CustomAppButton(
                text: isEditing ? 'Update Follow Up' : 'Save Follow Up',
                onPressed: _saveFollowUp,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
}

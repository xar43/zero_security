import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toggle_timer/config/api/api_services.dart';
import 'package:toggle_timer/config/colors/app_colors.dart';
import 'package:toggle_timer/config/constants/url_constants.dart';
import 'package:toggle_timer/config/local/local_storage_services.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/core/utils/app_utils.dart';
import 'package:toggle_timer/features/sales/models/lead_model.dart';

import '../../../config/typography/app_typography.dart';
import '../../../core/common_widgets/custom_app_button.dart';
import '../../../core/common_widgets/custom_text_field.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.lead});
  final LeadModel? lead;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  LeadModel? _currentLead;
  bool _isGlobal = false;
  List<TaskModel> _globalTasks = [];
  Map<String, LeadModel> _taskToLeadMap = {};
  List<LeadModel> _allLeadsList = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Open', 'Closed', 'Pending', 'In Progress', 'Completed', 'Overdue', 'Today'];

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      _currentLead = widget.lead;
    } else {
      _isGlobal = true;
      _loadGlobalTasks();
    }
  }

  Future<void> _loadGlobalTasks() async {
    setState(() => _isLoading = true);
    final allLeads = await LeadModel.getAll();
    final tasks = <TaskModel>[];
    final map = <String, LeadModel>{};
    for (var l in allLeads) {
      tasks.addAll(l.taskModels);
      for (var t in l.taskModels) {
        map[t.id] = l;
      }
    }

    // Backend se bhi todo list fetch karo
    final empId = LocalStorageServices.getEmployeeId();
    final company = LocalStorageServices.getCompany();
    if (empId != null && company != null) {
      try {
        final apiServices = ApiServices();
        final response = await apiServices.postRequest(
          UrlConstants.todoListUrl,
          body: {"employee_id": empId, "company": company},
        );
        debugPrint('✅ Todo list from backend: $response');
      } catch (e) {
        debugPrint('⚠️ Todo list fetch failed: $e');
      }
    }

    setState(() {
      _allLeadsList = allLeads;
      _globalTasks = tasks;
      _taskToLeadMap = map;
      _isLoading = false;
    });
  }

  List<TaskModel> get _sourceTasks => _isGlobal ? _globalTasks : _currentLead!.taskModels;

  List<TaskModel> get _filteredTasks {
    final tasks = _sourceTasks;
    switch (_selectedFilter) {
      case 'Open':
        return tasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress).toList();
      case 'Closed':
        return tasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.cancelled).toList();
      case 'Pending':
        return tasks.where((t) => t.status == TaskStatus.pending).toList();
      case 'In Progress':
        return tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case 'Completed':
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case 'Overdue':
        return tasks.where((t) => t.isOverdue).toList();
      case 'Today':
        return tasks.where((t) => t.isDueToday).toList();
      case 'All':
      default:
        return tasks;
    }
  }

  Future<void> _addNewTask() async {
    final result = await showAddTaskBottomSheet(
      context: context,
      isGlobal: _isGlobal,
      allLeads: _isGlobal ? _allLeadsList : null,
    );

    if (result != null) {
      final task = result.$1;
      final selectedLead = result.$2;
      
      setState(() => _isLoading = true);

      if (!_isGlobal) {
        final updatedLead = _currentLead!.addTask(task);
        await updatedLead.save();
        setState(() {
          _currentLead = updatedLead;
        });
      } else {
        if (selectedLead != null) {
          final updatedLead = selectedLead.addTask(task);
          await updatedLead.save();
          _taskToLeadMap[task.id] = updatedLead;
          _globalTasks.add(task);
          final leadIdx = _allLeadsList.indexWhere((l) => l.id == selectedLead.id);
          if (leadIdx != -1) _allLeadsList[leadIdx] = updatedLead;
          setState(() {});
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        AppPrompts.showSuccess(message: 'Task added successfully', title: 'Success');
      }
    }
  }

  Future<void> _editTask(TaskModel task) async {
    final leadForTask = _isGlobal ? _taskToLeadMap[task.id] : _currentLead;
    final result = await showAddTaskBottomSheet(
      context: context, 
      task: task,
      isGlobal: _isGlobal,
      allLeads: _isGlobal ? _allLeadsList : null,
      preselectedLead: leadForTask,
    );

    if (result != null) {
      final editedTask = result.$1;
      setState(() => _isLoading = true);

      if (!_isGlobal) {
        final updatedLead = _currentLead!.updateTask(editedTask.id, editedTask);
        await updatedLead.save();
        setState(() {
          _currentLead = updatedLead;
        });
      } else {
        final lead = _taskToLeadMap[editedTask.id];
        if (lead != null) {
          final updatedLead = lead.updateTask(editedTask.id, editedTask);
          await updatedLead.save();
          _taskToLeadMap[editedTask.id] = updatedLead;
          final idx = _globalTasks.indexWhere((t) => t.id == editedTask.id);
          if (idx != -1) _globalTasks[idx] = editedTask;
          final leadIdx = _allLeadsList.indexWhere((l) => l.id == lead.id);
          if (leadIdx != -1) _allLeadsList[leadIdx] = updatedLead;
          setState(() {});
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        AppPrompts.showSuccess(message: 'Task updated successfully', title: 'Success');
      }
    }
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    setState(() => _isLoading = true);

    final updatedTask = task.copyWith(
      status: task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed,
      completedDate: task.status == TaskStatus.completed ? null : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!_isGlobal) {
      final updatedLead = _currentLead!.updateTask(task.id, updatedTask);
      await updatedLead.save();
      setState(() {
        _currentLead = updatedLead;
      });
    } else {
      final lead = _taskToLeadMap[task.id];
      if (lead != null) {
        final updatedLead = lead.updateTask(task.id, updatedTask);
        await updatedLead.save();
        _taskToLeadMap[task.id] = updatedLead;
        final idx = _globalTasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) _globalTasks[idx] = updatedTask;
        setState(() {});
      }
    }

    // Backend par toggle status bhi bhejo
    final empId = LocalStorageServices.getEmployeeId();
    final company = LocalStorageServices.getCompany();
    if (empId != null && company != null) {
      try {
        final apiServices = ApiServices();
        final newStatus = updatedTask.status == TaskStatus.completed ? 'Complete' : 'Incomplte';
        await apiServices.patchRequest(
          UrlConstants.toggleTodoStatusUrl,
          body: {
            "task_id": task.id,
            "status": newStatus,
            "employee_id": empId,
            "company": company,
          },
        );
        debugPrint('✅ Toggle status backend update: $newStatus');
      } catch (e) {
        debugPrint('⚠️ Toggle status backend failed: $e');
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (updatedTask.status == TaskStatus.completed) {
        AppPrompts.showSuccess(message: 'Task marked as completed', title: 'Great Job!');
      } else {
        AppPrompts.showInfo(message: 'Task reopened', title: 'Info');
      }
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    await AppPrompts.showConfirmation(
      context: context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"?',
      onConfirm: () async {
        setState(() => _isLoading = true);

        if (!_isGlobal) {
          final updatedLead = _currentLead!.removeTask(task.id);
          await updatedLead.save();
          setState(() {
            _currentLead = updatedLead;
          });
        } else {
          final lead = _taskToLeadMap[task.id];
          if (lead != null) {
            final updatedLead = lead.removeTask(task.id);
            await updatedLead.save();
            _taskToLeadMap[task.id] = updatedLead;
            _globalTasks.removeWhere((t) => t.id == task.id);
            setState(() {});
          }
        }

        setState(() => _isLoading = false);

        if (mounted) {
          AppPrompts.showSuccess(message: 'Task deleted successfully', title: 'Deleted');
        }
      },
    );
  }

  Future<void> _respondToTask(TaskModel task) async {
    final responseController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.kAppCardColor,
          title: Text('Respond to Task', style: AppTypography.style18SemiBold.copyWith(color: AppColors.kAppWhite)),
          content: CustomTextField(
            controller: responseController,
            hintText: 'Enter your response...',
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final responseText = responseController.text.trim();
                if (responseText.isEmpty) return;

                Navigator.pop(context); // Close dialog
                setState(() => _isLoading = true);

                final empId = LocalStorageServices.getEmployeeId();
                final company = LocalStorageServices.getCompany();

                if (empId != null && company != null) {
                  try {
                    final apiServices = ApiServices();
                    await apiServices.patchRequest(
                      UrlConstants.respondTodoUrl,
                      body: {
                        "employee_id": empId,
                        "company": company,
                        "task_id": task.id,
                        "response": responseText,
                      },
                    );
                    debugPrint('✅ Task response submitted: $responseText');
                    if (mounted) {
                      AppPrompts.showSuccess(message: 'Response submitted successfully');
                    }
                  } catch (e) {
                    debugPrint('⚠️ Task response failed: $e');
                    if (mounted) {
                      AppPrompts.showError(message: 'Failed to submit response');
                    }
                  }
                } else {
                  debugPrint('⚠️ empId/company null - cannot respond to backend');
                  if (mounted) {
                    AppPrompts.showError(message: 'Session expired. Cannot respond.');
                  }
                }
                setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kAppPrimary),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        title: const Text('Tasks'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addNewTask)],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(top: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;

                    // Get count for filter
                    int count = 0;
                    final sourceTasks = _sourceTasks;
                    switch (filter) {
                      case 'All':
                        count = sourceTasks.length;
                        break;
                      case 'Open':
                        count = sourceTasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress).length;
                        break;
                      case 'Closed':
                        count = sourceTasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.cancelled).length;
                        break;
                      case 'Pending':
                        count = sourceTasks.where((t) => t.status == TaskStatus.pending).length;
                        break;
                      case 'In Progress':
                        count = sourceTasks.where((t) => t.status == TaskStatus.inProgress).length;
                        break;
                      case 'Completed':
                        count = sourceTasks.where((t) => t.status == TaskStatus.completed).length;
                        break;
                      case 'Overdue':
                        count = sourceTasks.where((t) => t.isOverdue).length;
                        break;
                      case 'Today':
                        count = sourceTasks.where((t) => t.isDueToday).length;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$filter ${count > 0 ? '($count)' : ''}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue,
                        labelStyle: AppTypography.style14Regular.copyWith(
                          color: isSelected ? Colors.blue : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Tasks List
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: AppTypography.style18SemiBold.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new task',
                              style: AppTypography.style14Regular.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => _editTask(task),
                            onToggleStatus: () => _toggleTaskStatus(task),
                            onDelete: () => _deleteTask(task),
                            onRespond: () => _respondToTask(task),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Task Card Widget
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onRespond;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onRespond,
  });

  String get _statusText {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: const Color.fromARGB(255, 69, 69, 69),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: task.priorityColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppTypography.style16SemiBold.copyWith(
                              decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                              color: task.status == TaskStatus.completed ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.kAppWhite),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      } else if (value == 'respond') {
                        onRespond();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'respond',
                        child: Row(
                          children: [
                            const Icon(Icons.reply, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('Respond', style: AppTypography.style14Regular.copyWith(color: Colors.blue)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text('Delete', style: AppTypography.style14Regular.copyWith(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: AppTypography.style14Regular.copyWith(color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Row(
                children: [
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(task.statusIcon, size: 14, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(_statusText, style: AppTypography.style12SemiBold.copyWith(color: _statusColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Due Date
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            task.isOverdue ? Icons.warning_amber_rounded : Icons.access_time,
                            size: 14,
                            color: task.isOverdue ? Colors.red : Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(task.dueDate!),
                            style: AppTypography.style12Regular.copyWith(
                              color: task.isOverdue ? Colors.red : Colors.black,
                              fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Checkbox for completion
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: (_) => onToggleStatus(),
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);

    if (dueDate == today) {
      return 'Today';
    } else if (dueDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dueDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Add Task Bottom Sheet
Future<(TaskModel, LeadModel?)?> showAddTaskBottomSheet({
  required BuildContext context, 
  TaskModel? task,
  bool isGlobal = false,
  List<LeadModel>? allLeads,
  LeadModel? preselectedLead,
}) {
  return showModalBottomSheet<(TaskModel, LeadModel?)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTaskBottomSheet(
      task: task,
      isGlobal: isGlobal,
      allLeads: allLeads,
      preselectedLead: preselectedLead,
    ),
  );
}

class AddTaskBottomSheet extends StatefulWidget {
  final TaskModel? task;
  final bool isGlobal;
  final List<LeadModel>? allLeads;
  final LeadModel? preselectedLead;

  const AddTaskBottomSheet({
    super.key, 
    this.task,
    this.isGlobal = false,
    this.allLeads,
    this.preselectedLead,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  late DateTime? _selectedDueDate;
  late bool _isReminderSet;
  late DateTime? _reminderTime;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _attachments = [];
  final bool _isLoading = false;
  LeadModel? _selectedLead;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedDueDate = widget.task?.dueDate ?? DateTime.now();
    _isReminderSet = widget.task?.isReminderSet ?? false;
    _reminderTime = widget.task?.reminderTime;
    _attachments = widget.task?.attachments ?? [];
    _selectedLead = widget.preselectedLead;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _pickReminderTime() async {
    if (_selectedDueDate == null) {
      AppPrompts.showInfo(message: 'Please select due date first');
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      final reminderDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        time.hour,
        time.minute,
      );
      setState(() {
        _reminderTime = reminderDateTime;
        _isReminderSet = true;
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _attachments.add(pickedFile.path);
        });
        AppPrompts.showSuccess(message: 'Attachment added successfully', title: 'Success');
      }
    } catch (e) {
      AppPrompts.showError(message: 'Failed to pick image: $e', title: 'Error');
    }
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = TaskModel(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: widget.task?.status ?? TaskStatus.pending,
        dueDate: _selectedDueDate,
        completedDate: widget.task?.completedDate,
        isReminderSet: _isReminderSet,
        reminderTime: _reminderTime,
        attachments: _attachments.isEmpty ? null : _attachments,
        assignedTo: widget.task?.assignedTo,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, (task, _selectedLead));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(widget.task == null ? Icons.add_task : Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.task == null ? 'Add New Task' : 'Edit Task',
                  style: AppTypography.style20SemiBold.copyWith(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isGlobal && widget.allLeads != null) ...[
                      Text('Select Lead', style: AppTypography.style16SemiBold.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LeadModel>(
                        value: _selectedLead,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        dropdownColor: const Color(0xFF2A2A2A),
                        items: widget.allLeads!.map((lead) {
                          return DropdownMenuItem(
                            value: lead,
                            child: Text(lead.name, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: widget.task == null ? (val) => setState(() => _selectedLead = val) : null,
                        validator: (val) => val == null ? 'Lead is required' : null,
                        hint: const Text('Select a lead', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title Field
                    CustomTextField(
                      controller: _titleController,
                      headingLabelText: 'Task Title',
                      isRequired: true,
                      hintText: 'Enter task title',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Task title is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Task title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    CustomTextField(
                      controller: _descriptionController,
                      headingLabelText: 'Description',
                      hintText: 'Enter task description',
                      maxLines: 3,
                      minLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // Priority Selection
                    Text('Priority', style: AppTypography.style16SemiBold.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildPriorityChip(TaskPriority.low, 'Low')),
                        Expanded(child: _buildPriorityChip(TaskPriority.medium, 'Medium')),
                        Expanded(child: _buildPriorityChip(TaskPriority.high, 'High')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Due Date
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: _selectedDueDate != null ? Colors.blue : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDueDate != null
                                    ? 'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                    : 'Set Due Date',
                                style: AppTypography.style16Regular.copyWith(
                                  color: _selectedDueDate != null ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                            if (_selectedDueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () => setState(() => _selectedDueDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reminder
                    GestureDetector(
                      onTap: _pickReminderTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications, color: _isReminderSet ? Colors.blue : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isReminderSet && _reminderTime != null
                                    ? 'Reminder: ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Set Reminder',
                                style: AppTypography.style16Regular.copyWith(
                                  color: _isReminderSet ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                            if (_isReminderSet)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () => setState(() {
                                  _isReminderSet = false;
                                  _reminderTime = null;
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attachments
                    if (_attachments.isNotEmpty) ...[
                      Text('Attachments', style: AppTypography.style16SemiBold.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[800]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_attachments[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _attachments.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Add Attachment Button
                    TextButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.attach_file, color: Colors.blue),
                      label: Text('Add Attachment', style: AppTypography.style16Regular.copyWith(color: Colors.blue)),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Footer Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Colors.grey[600]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Cancel', style: AppTypography.style16SemiBold.copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomAppButton(
                    text: widget.task == null ? 'Add Task' : 'Update Task',
                    onPressed: _saveTask,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, String label) {
    final isSelected = _selectedPriority == priority;
    Color color;
    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        break;
      case TaskPriority.high:
        color = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPriority = priority);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey[800]!, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(label, style: AppTypography.style14SemiBold.copyWith(color: isSelected ? color : Colors.grey)),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../../../config/local/sql_database.dart';

// ========== LOCATION SESSION MODEL ==========
class LocationSession {
  final String startTime;
  final String endTime;
  final String startLocation;
  final String endLocation;
  final List<String> hourlyLocations;

  const LocationSession({
    required this.startTime,
    required this.endTime,
    required this.startLocation,
    required this.endLocation,
    required this.hourlyLocations,
  });

  factory LocationSession.fromJson(Map<String, dynamic> json) => LocationSession(
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    startLocation: json['startLocation'] as String,
    endLocation: json['endLocation'] as String,
    hourlyLocations: List<String>.from(json['hourlyLocations'] as List),
  );

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    'startLocation': startLocation,
    'endLocation': endLocation,
    'hourlyLocations': hourlyLocations,
  };

  LocationSession copyWith({
    String? startTime,
    String? endTime,
    String? startLocation,
    String? endLocation,
    List<String>? hourlyLocations,
  }) => LocationSession(
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    startLocation: startLocation ?? this.startLocation,
    endLocation: endLocation ?? this.endLocation,
    hourlyLocations: hourlyLocations ?? this.hourlyLocations,
  );
}

// ========== FOLLOW-UP MODEL ==========
class FollowUp {
  final String id;
  final DateTime? scheduledDate;
  final FollowUpType type;
  final FollowUpStatus status;
  final DateTime? completedDate;
  final String? notes;
  final bool isReminderSet;
  final bool isRepeat;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FollowUp({
    required this.id,
    this.scheduledDate,
    this.type = FollowUpType.call,
    this.status = FollowUpStatus.pending,
    this.completedDate,
    this.notes,
    this.isReminderSet = false,
    this.isRepeat = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
    id: json['id'] as String,
    scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate'] as String) : null,
    type: FollowUpType.values.firstWhere(
      (e) => e.toString() == json['type'] || e.name == json['type'],
      orElse: () => FollowUpType.call,
    ),
    status: FollowUpStatus.values.firstWhere(
      (e) => e.toString() == json['status'] || e.name == json['status'],
      orElse: () => FollowUpStatus.pending,
    ),
    completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate'] as String) : null,
    notes: json['notes'] as String?,
    isReminderSet: json['isReminderSet'] as bool? ?? false,
    isRepeat: json['isRepeat'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'type': type.name,
    'status': status.name,
    'completedDate': completedDate?.toIso8601String(),
    'notes': notes,
    'isReminderSet': isReminderSet,
    'isRepeat': isRepeat,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  FollowUp copyWith({
    String? id,
    DateTime? scheduledDate,
    FollowUpType? type,
    FollowUpStatus? status,
    DateTime? completedDate,
    String? notes,
    bool? isReminderSet,
    bool? isRepeat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FollowUp(
    id: id ?? this.id,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    type: type ?? this.type,
    status: status ?? this.status,
    completedDate: completedDate ?? this.completedDate,
    notes: notes ?? this.notes,
    isReminderSet: isReminderSet ?? this.isReminderSet,
    isRepeat: isRepeat ?? this.isRepeat,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum FollowUpType { call, email, meeting, other }

enum FollowUpStatus { pending, completed, cancelled }

// ========== ACTIVITY LOG MODEL ==========
class ActivityLog {
  final String id;
  final String activityType;
  final String description;
  final DateTime timestamp;

  const ActivityLog({required this.id, required this.activityType, required this.description, required this.timestamp});

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'] as String,
    activityType: json['activityType'] as String,
    description: json['description'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  ActivityLog copyWith({String? id, String? activityType, String? description, DateTime? timestamp}) => ActivityLog(
    id: id ?? this.id,
    activityType: activityType ?? this.activityType,
    description: description ?? this.description,
    timestamp: timestamp ?? this.timestamp,
  );
}

// ========== TASK MODEL ==========
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final bool isReminderSet;
  final DateTime? reminderTime;
  final List<String>? attachments;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.completedDate,
    this.isReminderSet = false,
    this.reminderTime,
    this.attachments,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
  });

  // Check if task is overdue
  bool get isOverdue {
    if (status == TaskStatus.completed || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  // Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year && dueDate!.month == today.month && dueDate!.day == today.day;
  }

  // Check if task is due tomorrow
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year && dueDate!.month == tomorrow.month && dueDate!.day == tomorrow.day;
  }

  // Get color based on priority
  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  // Get icon based on status
  IconData get statusIcon {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_outlined;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    priority: TaskPriority.values.firstWhere(
      (e) => e.toString() == json['priority'] || e.name == json['priority'],
      orElse: () => TaskPriority.medium,
    ),
    status: TaskStatus.values.firstWhere(
      (e) => e.toString() == json['status'] || e.name == json['status'],
      orElse: () => TaskStatus.pending,
    ),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate'] as String) : null,
    isReminderSet: json['isReminderSet'] as bool? ?? false,
    reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime'] as String) : null,
    attachments: json['attachments'] != null ? List<String>.from(jsonDecode(json['attachments'])) : null,
    assignedTo: json['assignedTo'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.name,
    'status': status.name,
    'dueDate': dueDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'isReminderSet': isReminderSet,
    'reminderTime': reminderTime?.toIso8601String(),
    'attachments': attachments != null ? jsonEncode(attachments) : null,
    'assignedTo': assignedTo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? completedDate,
    bool? isReminderSet,
    DateTime? reminderTime,
    List<String>? attachments,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    dueDate: dueDate ?? this.dueDate,
    completedDate: completedDate ?? this.completedDate,
    isReminderSet: isReminderSet ?? this.isReminderSet,
    reminderTime: reminderTime ?? this.reminderTime,
    attachments: attachments ?? this.attachments,
    assignedTo: assignedTo ?? this.assignedTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed, cancelled }

// ========== LEAD MODEL ==========
class LeadModel {
  final String? id;
  final String name;
  final String? notes;
  final String address;
  final int? createdAt;
  final int? updatedAt;
  final String contactInfo;
  final String? companyName;
  final String? proposalLink;
  final List<FollowUp> followUps;
  final List<TaskModel> taskModels;
  final List<String> recordingPaths;
  final String? visitingCardImagePath;
  final List<String> documentImagePaths;
  final List<ActivityLog> activityHistory;
  final Map<String, LocationSession>? dailyLocationMap;

  // SQL Table name
  static const String _tableName = 'leads';

  const LeadModel({
    this.id,
    required this.name,
    required this.address,
    required this.contactInfo,
    this.companyName,
    this.notes,
    this.visitingCardImagePath,
    this.documentImagePaths = const [],
    this.followUps = const [],
    this.activityHistory = const [],
    this.taskModels = const [],
    this.recordingPaths = const [],
    this.proposalLink,
    this.createdAt,
    this.updatedAt,
    this.dailyLocationMap,
  });

  FollowUp? get nextFollowUp => followUps.firstWhereOrNull((f) => f.status == FollowUpStatus.pending);

  // Get overdue follow-ups
  List<FollowUp> get overdueFollowUps => followUps
      .where((followUp) => followUp.status == FollowUpStatus.pending)
      .where((followUp) => followUp.scheduledDate != null)
      .where((followUp) => followUp.scheduledDate!.isBefore(DateTime.now()))
      .toList();

  // Get today's follow-ups
  List<FollowUp> get todaysFollowUps => followUps
      .where((followUp) => followUp.status == FollowUpStatus.pending)
      .where((followUp) => followUp.scheduledDate != null)
      .where((followUp) {
        final today = DateTime.now();
        return followUp.scheduledDate!.year == today.year &&
            followUp.scheduledDate!.month == today.month &&
            followUp.scheduledDate!.day == today.day;
      })
      .toList();

  LeadModel copyWith({
    String? id,
    String? name,
    String? notes,
    int? createdAt,
    int? updatedAt,
    String? address,
    String? contactInfo,
    String? companyName,
    String? proposalLink,
    List<FollowUp>? followUps,
    List<TaskModel>? taskModels,
    List<String>? recordingPaths,
    String? visitingCardImagePath,
    List<String>? documentImagePaths,
    List<ActivityLog>? activityHistory,
    Map<String, LocationSession>? dailyLocationMap,
  }) => LeadModel(
    id: id ?? this.id,
    recordingPaths: recordingPaths ?? this.recordingPaths,
    name: name ?? this.name,
    address: address ?? this.address,
    contactInfo: contactInfo ?? this.contactInfo,
    companyName: companyName ?? this.companyName,
    notes: notes ?? this.notes,
    visitingCardImagePath: visitingCardImagePath ?? this.visitingCardImagePath,
    documentImagePaths: documentImagePaths ?? this.documentImagePaths,
    followUps: followUps ?? this.followUps,
    activityHistory: activityHistory ?? this.activityHistory,
    taskModels: taskModels ?? this.taskModels,
    proposalLink: proposalLink ?? this.proposalLink,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dailyLocationMap: dailyLocationMap ?? this.dailyLocationMap,
  );

  // ========== 5 MOST IMPORTANT METHODS ==========

  // 1. CREATE TABLE METHOD
  static Future<void> createTable(Database db) async {
    const createTableQuery =
        '''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        contactInfo TEXT NOT NULL,
        companyName TEXT,
        notes TEXT,
        taskModels TEXT,
        visitingCardImagePath TEXT,
        documentImagePaths TEXT,
        recordingPaths TEXT,
        followUps TEXT,
        activityHistory TEXT,
        proposalLink TEXT,
        dailyLocationMap TEXT,
        createdAt INTEGER DEFAULT (strftime('%s', 'now')),
        updatedAt INTEGER DEFAULT (strftime('%s', 'now')),
        search_text TEXT
      )
    ''';

    await db.execute(createTableQuery);

    // Create indices for fast queries
    const indices = [
      'CREATE INDEX IF NOT EXISTS idx_leads_name ON $_tableName (name)',
      'CREATE INDEX IF NOT EXISTS idx_leads_contactInfo ON $_tableName (contactInfo)',
      'CREATE INDEX IF NOT EXISTS idx_leads_search ON $_tableName (search_text)',
    ];

    for (final indexQuery in indices) {
      await db.execute(indexQuery);
    }
  }

  // 2. SAVE/UPDATE LEAD
  Future<int> save() async {
    final db = await SQLDatabase.leadTableDb;

    // Generate ID if new lead
    final leadId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(_tableName, {
      'id': leadId,
      'name': name,
      'address': address,
      'contactInfo': contactInfo,
      'companyName': companyName,
      'notes': notes,
      'taskModels': jsonEncode(taskModels.map((t) => t.toJson()).toList()),
      'visitingCardImagePath': visitingCardImagePath,
      'documentImagePaths': jsonEncode(documentImagePaths),
      'recordingPaths': jsonEncode(recordingPaths),
      'followUps': jsonEncode(followUps.map((f) => f.toJson()).toList()),
      'activityHistory': jsonEncode(activityHistory.map((log) => log.toJson()).toList()),
      'proposalLink': proposalLink,
      'dailyLocationMap': dailyLocationMap != null
          ? jsonEncode(dailyLocationMap!.map((key, value) => MapEntry(key, value.toJson())))
          : null,
      'updatedAt': now,
      'search_text': '${name.toLowerCase()} ${contactInfo.toLowerCase()} ${companyName?.toLowerCase() ?? ""}',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 3. GET TODAY'S FOLLOW-UPS
  static Future<List<LeadModel>> getTodaysFollowUps() async {
    final db = await SQLDatabase.leadTableDb;

    const query = 'SELECT * FROM $_tableName';
    final result = await db.rawQuery(query);
    
    // Filter leads that have today's follow-ups
    final leads = result.map(LeadModel.fromMap).toList();
    return leads.where((lead) => lead.todaysFollowUps.isNotEmpty).toList();
  }

  // 4. SEARCH LEADS
  static Future<List<LeadModel>> search(String query, {int limit = 50}) async {
    final db = await SQLDatabase.leadTableDb;
    final searchTerm = '%$query%';

    final searchQuery =
        '''
      SELECT * FROM $_tableName 
      WHERE search_text LIKE ? 
        OR name LIKE ?
        OR address LIKE ?
        OR contactInfo LIKE ?
        OR companyName LIKE ?
      ORDER BY 
        CASE 
          WHEN name LIKE ? THEN 1
          WHEN address LIKE ? THEN 2
          WHEN contactInfo LIKE ? THEN 3
          WHEN companyName LIKE ? THEN 4
          ELSE 5
        END,
        updatedAt DESC
      LIMIT $limit
    ''';

    final result = await db.rawQuery(searchQuery, [
      searchTerm,
      searchTerm,
      searchTerm,
      searchTerm,
      '$query%',
      '$query%',
      '$query%',
    ]);

    return result.map(LeadModel.fromMap).toList();
  }

  // 5. GET PENDING FOLLOW-UPS (with overdue)
  static Future<Map<String, List<LeadModel>>> getPendingFollowUps() async {
    final db = await SQLDatabase.leadTableDb;
    
    const query = 'SELECT * FROM $_tableName';
    final result = await db.rawQuery(query);
    final leads = result.map(LeadModel.fromMap).toList();

    // Separate leads into today and overdue based on their follow-ups
    final todayLeads = leads.where((lead) => lead.todaysFollowUps.isNotEmpty).toList();
    final overdueLeads = leads.where((lead) => lead.overdueFollowUps.isNotEmpty).toList();

    return {
      'today': todayLeads, 'overdue': overdueLeads,
    };
  }

  // ========== TASK MANAGEMENT METHODS ==========

  // Add a new task
  LeadModel addTask(TaskModel task) {
    final updatedTasks = List<TaskModel>.from(taskModels)..add(task);
    return copyWith(taskModels: updatedTasks);
  }

  // Update an existing task
  LeadModel updateTask(String taskId, TaskModel updatedTask) {
    final updatedTasks = taskModels.map((t) => t.id == taskId ? updatedTask : t).toList();
    return copyWith(taskModels: updatedTasks);
  }

  // Remove a task
  LeadModel removeTask(String taskId) {
    final updatedTasks = taskModels.where((t) => t.id != taskId).toList();
    return copyWith(taskModels: updatedTasks);
  }

  // Mark task as completed
  LeadModel completeTask(String taskId) {
    final updatedTasks = taskModels.map((t) {
      if (t.id == taskId) {
        return t.copyWith(status: TaskStatus.completed, completedDate: DateTime.now(), updatedAt: DateTime.now());
      }
      return t;
    }).toList();

    return copyWith(taskModels: updatedTasks);
  }

  // Get pending tasks
  List<TaskModel> get pendingTasks =>
      taskModels.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress).toList();

  // Get completed tasks
  List<TaskModel> get completedTasks => taskModels.where((t) => t.status == TaskStatus.completed).toList();

  // Get overdue tasks
  List<TaskModel> get overdueTasks => pendingTasks.where((t) => t.isOverdue).toList();

  // Get today's tasks
  List<TaskModel> get todaysTasks => pendingTasks.where((t) => t.isDueToday).toList();

  // Get tasks by priority
  List<TaskModel> getTasksByPriority(TaskPriority priority) => taskModels.where((t) => t.priority == priority).toList();

  // ========== LOCATION MANAGEMENT METHODS ==========

  // Add or update a location session
  LeadModel updateLocationSession(String dateKey, LocationSession session) {
    final updatedMap = Map<String, LocationSession>.from(dailyLocationMap ?? {});
    updatedMap[dateKey] = session;
    return copyWith(dailyLocationMap: updatedMap);
  }

  // Get location sessions for a specific date
  LocationSession? getLocationSession(String dateKey) {
    return dailyLocationMap?[dateKey];
  }

  // Get all location sessions sorted by date (most recent first)
  List<MapEntry<String, LocationSession>> getSortedLocationSessions() {
    if (dailyLocationMap == null) return [];
    final entries = dailyLocationMap!.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  // Get active location session (if any)
  LocationSession? getActiveLocationSession() {
    try {
      return dailyLocationMap?.values.firstWhere((session) => session.endTime.isEmpty);
    } catch (_) {
      return null;
    }
  }

  // Check if there's an active tracking session
  bool get hasActiveTracking {
    return getActiveLocationSession() != null;
  }

  // Get total tracked locations count
  int get totalTrackedLocations {
    if (dailyLocationMap == null) return 0;
    return dailyLocationMap!.values.fold(0, (sum, session) => sum + session.hourlyLocations.length);
  }

  // Get total tracking sessions count
  int get totalTrackingSessions {
    return dailyLocationMap?.length ?? 0;
  }

  // Get today's location session if exists
  LocationSession? get todaysLocationSession {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dailyLocationMap?[todayKey];
  }

  // ========== HELPER METHODS ==========

  // Convert from SQL map
  factory LeadModel.fromMap(Map<String, dynamic> map) {
    final documentImagePaths = map['documentImagePaths'] as String?;
    final followUpsJson = map['followUps'] as String?;
    final activityHistory = map['activityHistory'] as String?;
    final taskModelsJson = map['taskModels'] as String?;
    final recordingPathsJson = map['recordingPaths'] as String?;
    final dailyLocationMapJson = map['dailyLocationMap'] as String?;
    final createdAt = map['createdAt'] as int?;
    final updatedAt = map['updatedAt'] as int?;

    return LeadModel(
      id: map['id'] as String,
      address: map['address'] as String,
      name: map['name'] as String,
      contactInfo: map['contactInfo'] as String,
      companyName: map['companyName'] as String?,
      notes: map['notes'] as String?,
      visitingCardImagePath: map['visitingCardImagePath'] as String?,
      documentImagePaths: documentImagePaths != null ? List<String>.from(jsonDecode(documentImagePaths)) : [],
      followUps:
          followUpsJson != null
          ? (jsonDecode(followUpsJson) as List?)?.map((i) => FollowUp.fromJson(i)).toList() ?? []
          : [],
      activityHistory:
          (jsonDecode(activityHistory ?? '[]') as List?)?.map((i) => ActivityLog.fromJson(i)).toList() ?? [],
      taskModels: taskModelsJson != null
          ? (jsonDecode(taskModelsJson) as List?)?.map((i) => TaskModel.fromJson(i)).toList() ?? []
          : [],
      proposalLink: map['proposalLink'] as String?,
      recordingPaths: recordingPathsJson != null ? List<String>.from(jsonDecode(recordingPathsJson)) : [],
      createdAt: createdAt,
      updatedAt: updatedAt,
      dailyLocationMap: dailyLocationMapJson != null
          ? Map<String, LocationSession>.from(
              (jsonDecode(dailyLocationMapJson) as Map).map(
                (key, value) => MapEntry(key, LocationSession.fromJson(value)),
              ),
            )
          : null,
    );
  }

  // Convert to SQL map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'contactInfo': contactInfo,
    'companyName': companyName,
    'notes': notes,
    'taskModels': jsonEncode(taskModels.map((t) => t.toJson()).toList()),
    'visitingCardImagePath': visitingCardImagePath,
    'documentImagePaths': jsonEncode(documentImagePaths),
    'followUps': jsonEncode(followUps.map((f) => f.toJson()).toList()),
    'activityHistory': jsonEncode(activityHistory.map((log) => log.toJson()).toList()),
    'proposalLink': proposalLink,
    'recordingPaths': jsonEncode(recordingPaths),
    'dailyLocationMap': dailyLocationMap != null
        ? jsonEncode(dailyLocationMap!.map((key, value) => MapEntry(key, value.toJson())))
        : null,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  // Add a new follow-up
  LeadModel addFollowUp(FollowUp followUp) {
    final updatedFollowUps = List<FollowUp>.from(followUps)..add(followUp);
    return copyWith(followUps: updatedFollowUps);
  }

  // Update an existing follow-up
  LeadModel updateFollowUp(String followUpId, FollowUp updatedFollowUp) {
    final updatedFollowUps = followUps.map((f) => f.id == followUpId ? updatedFollowUp : f).toList();
    return copyWith(followUps: updatedFollowUps);
  }

  // Mark follow-up as completed
  LeadModel completeFollowUp(String followUpId, String notes) {
    final updatedFollowUps = followUps.map((f) {
      if (f.id == followUpId) {
        return f.copyWith(status: FollowUpStatus.completed, completedDate: DateTime.now(), notes: notes);
      }
      return f;
    }).toList();

    return copyWith(followUps: updatedFollowUps);
  }

  // Add activity log
  LeadModel addActivity(String activityType, String description) {
    final newLog = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityType: activityType,
      description: description,
      timestamp: DateTime.now(),
    );

    final updatedHistory = List<ActivityLog>.from(activityHistory)..add(newLog);

    return copyWith(activityHistory: updatedHistory);
  }

  // Get display name
  String get displayName => (companyName != null && companyName!.isNotEmpty) ? '$name ($companyName)' : name;

  // Get all leads
  static Future<List<LeadModel>> getAll({int limit = 100}) async {
    final db = await SQLDatabase.leadTableDb;
    final result = await db.query(_tableName, orderBy: 'updatedAt DESC', limit: limit);
    return result.map(LeadModel.fromMap).toList();
  }

  // Delete lead
  Future<int> delete() async {
    final db = await SQLDatabase.leadTableDb;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Update lead
  Future<int> update() async {
    final db = await SQLDatabase.leadTableDb;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.update(_tableName, {...toMap(), 'updatedAt': now}, where: 'id = ?', whereArgs: [id]);
  }

  // Get leads with active tracking
  static Future<List<LeadModel>> getLeadsWithActiveTracking() async {
    final db = await SQLDatabase.leadTableDb;
    const query = 'SELECT * FROM $_tableName WHERE dailyLocationMap IS NOT NULL';
    final result = await db.rawQuery(query);
    final leads = result.map(LeadModel.fromMap).toList();
    
    // Filter leads that actually have active tracking sessions
    return leads.where((lead) => lead.hasActiveTracking).toList();
  }

  // Get leads with location history
  static Future<List<LeadModel>> getLeadsWithLocationHistory() async {
    final db = await SQLDatabase.leadTableDb;
    const query = 'SELECT * FROM $_tableName WHERE dailyLocationMap IS NOT NULL';
    final result = await db.rawQuery(query);
    return result.map(LeadModel.fromMap).toList();
  }
}

import 'package:sqflite/sqflite.dart';

import '../../../config/local/sql_database.dart';

class DashboardModel {
  final int id;
  final String activeTime;
  final String inCallTime;
  final String userStatus;
  final int recordedAt;
  final String? userId;
  final String date;

  // SQL Table name
  static const String tableName = 'dashboard_metrics';

  const DashboardModel({
    required this.id,
    required this.activeTime,
    required this.inCallTime,
    required this.userStatus,
    required this.recordedAt,
    this.userId,
    required this.date,
  });

  // ========== 5 MOST IMPORTANT METHODS ==========

  // 1. CREATE TABLE METHOD
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activeTime TEXT NOT NULL,
        inCallTime TEXT NOT NULL,
        userStatus TEXT NOT NULL,
        recordedAt INTEGER NOT NULL,
        userId TEXT,
        date TEXT
      )
    ''');

    // Create indices for efficient queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dashboard_date ON $tableName (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dashboard_userId ON $tableName (userId)');
  }

  // 2. SAVE/UPDATE DASHBOARD METRICS
  Future<int> save({String? userId}) async {
    final db = await SQLDatabase.dashboardDb;

    // For dashboard metrics, we usually want only one record per user per day
    final now = DateTime.now();
    final today = _formatDate(now);

    // Check if record exists for today
    final existing = await getTodayMetrics(userId: userId);

    if (existing != null) {
      // Update existing record
      return await db.update(
        tableName,
        {
          'activeTime': activeTime,
          'inCallTime': inCallTime,
          'userStatus': userStatus,
          'recordedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new record
      return await db.insert(tableName, {
        'activeTime': activeTime,
        'inCallTime': inCallTime,
        'userStatus': userStatus,
        'recordedAt': now.millisecondsSinceEpoch,
        'userId': userId,
        'date': today,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 3. GET TODAY'S METRICS
  static Future<DashboardModel?> getTodayMetrics({String? userId}) async {
    final db = await SQLDatabase.dashboardDb;
    final today = _formatDate(DateTime.now());

    final where = <String>['date = ?'];
    final whereArgs = <dynamic>[today];

    if (userId != null) {
      where.add('userId = ?');
      whereArgs.add(userId);
    }

    final result = await db.query(
      tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'recordedAt DESC',
      limit: 1,
    );

    return result.isNotEmpty ? DashboardModel.fromMap(result.first) : null;
  }

  // 4. GET METRICS FOR DATE RANGE (for analytics)
  static Future<List<DashboardModel>> getMetricsForPeriod(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
    int? limit,
  }) async {
    final db = await SQLDatabase.dashboardDb;

    final where = <String>['date >= ?', 'date <= ?'];
    final whereArgs = <dynamic>[_formatDate(startDate), _formatDate(endDate)];

    if (userId != null) {
      where.add('userId = ?');
      whereArgs.add(userId);
    }

    final result = await db.query(
      tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date ASC, recordedAt ASC',
      limit: limit,
    );

    return result.map((map) => DashboardModel.fromMap(map)).toList();
  }

  // 5. GET USER STATUS SUMMARY
  static Future<Map<String, dynamic>> getUserStatusSummary({DateTime? date, String? userId}) async {
    final db = await SQLDatabase.dashboardDb;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (date != null) {
      where.add('date = ?');
      whereArgs.add(_formatDate(date));
    }

    if (userId != null) {
      where.add('userId = ?');
      whereArgs.add(userId);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        userStatus,
        COUNT(*) as count,
        AVG(activeTime) as avgActiveTime,
        AVG(inCallTime) as avgInCallTime
      FROM $tableName 
      $whereClause
      GROUP BY userStatus
      ORDER BY count DESC
    ''', whereArgs);

    return {'summary': result.map((row) => row).toList(), 'totalRecords': result.length};
  }

  // ========== HELPER METHODS ==========

  // Convert from SQL map
  factory DashboardModel.fromMap(Map<String, dynamic> map) => DashboardModel(
    id: map['id'] as int,
    recordedAt: map['recordedAt'] as int,
    userId: map['userId'] as String,
    date: map['date'] as String,
    activeTime: map['activeTime'] as String,
    inCallTime: map['inCallTime'] as String,
    userStatus: map['userStatus'] as String,
  );

  // Convert to SQL map
  Map<String, dynamic> toMap() => {
    'id': id,
    'recordedAt': recordedAt,
    'userId': userId,
    'date': date,
    'activeTime': activeTime,
    'inCallTime': inCallTime,
    'userStatus': userStatus,
  };

  // Helper: Format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Copy with method for immutability
  DashboardModel copyWith({
    int? id,
    String? activeTime,
    String? inCallTime,
    String? userStatus,
    int? recordedAt,
    String? userId,
    String? date,
  }) => DashboardModel(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    activeTime: activeTime ?? this.activeTime,
    inCallTime: inCallTime ?? this.inCallTime,
    userStatus: userStatus ?? this.userStatus,
  );

  @override
  String toString() {
    return 'DashboardModel(id: $id, activeTime: $activeTime, inCallTime: $inCallTime, userStatus: $userStatus)';
  }
}

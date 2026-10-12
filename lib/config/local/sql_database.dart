import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/home/models/dashboard_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/sales/models/lead_model.dart';

abstract class SQLDatabase {
  static String get _noteDbName => 'note_tables.db';
  static String get _dashboardDbName => 'dashboard_tables.db';
  static String get _leadDbName => 'lead_tables.db';
  // Table creators
  static final Map<String, List<Future<void> Function(Database)>> _tableCreators = {
    _noteDbName: [NoteModel.createTable],
    _dashboardDbName: [DashboardModel.createTable],
    _leadDbName: [LeadModel.createTable],
  };

  // Private database accessors
  static int get _dbVersion => 1;

  // Database instances cache
  static final Map<String, Database> _databaseInstances = {};

  static Future<Database> get noteTablesDb => _getDatabase(_noteDbName, _dbVersion);
  static Future<Database> get dashboardDb => _getDatabase(_dashboardDbName, _dbVersion);
  static Future<Database> get leadTableDb => _getDatabase(_leadDbName, _dbVersion);
  // Get database with proper initialization
  static Future<Database> _getDatabase(String dbName, int version) async {
    if (_databaseInstances.containsKey(dbName)) {
      return _databaseInstances[dbName]!;
    }

    final db = await openDatabase(
      join(await getDatabasesPath(), dbName),
      onCreate: (db, version) async {
        final creators = _tableCreators[dbName] ?? [];
        for (final creator in creators) {
          await creator(db);
        }
      },
      version: version,
    );

    _databaseInstances[dbName] = db;
    return db;
  }
}

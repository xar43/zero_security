import 'package:sqflite/sqflite.dart';

import '../../../config/local/sql_database.dart';

class NoteModel {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOpen;
  final String? listName;

  const NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.isOpen,
    this.listName,
  });
  static const String tableName = 'notes';

  // ... constructor and fields ...

  // ========== 5 MOST IMPORTANT METHODS ==========

  // 1. CREATE TABLE METHOD
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isOpen INTEGER NOT NULL DEFAULT 1,
        listName TEXT
      )
    ''');
  }

  // 2. GET ALL NOTES (with optional filtering)
  static Future<List<NoteModel>> getAll({bool? isOpen, String orderBy = 'updatedAt DESC'}) async {
    final db = await SQLDatabase.noteTablesDb;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (isOpen != null) {
      where.add('isOpen = ?');
      whereArgs.add(isOpen ? 1 : 0);
    }

    final whereClause = where.isNotEmpty ? where.join(' AND ') : null;

    final result = await db.query(tableName, where: whereClause, whereArgs: whereArgs, orderBy: orderBy);
    return result.map((map) => NoteModel.fromMap(map)).toList();
  }

  // 3. SAVE NOTE (insert or update)
  Future<int> save() async {
    final db = await SQLDatabase.noteTablesDb;

    if (id == 0) {
      // Insert new note
      final now = DateTime.now();
      final newNote = copyWith(createdAt: now, updatedAt: now);
      return await db.insert(tableName, newNote.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      // Update existing note
      final updatedNote = copyWith(updatedAt: DateTime.now());
      return await db.update(tableName, updatedNote.toMap(), where: 'id = ?', whereArgs: [id]);
    }
  }

  // 4. DELETE NOTE
  Future<int> delete() async {
    final db = await SQLDatabase.noteTablesDb;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // 5. SEARCH NOTES
  static Future<List<NoteModel>> search(String query) async {
    final db = await SQLDatabase.noteTablesDb;
    final searchTerm = '%$query%';
    final result = await db.rawQuery(
      '''
      SELECT * FROM $tableName 
      WHERE title LIKE ?
      ORDER BY updatedAt DESC
    ''',
      [searchTerm],
    );
    return result.map((map) => NoteModel.fromMap(map)).toList();
  }

  // Helper: Convert from SQL map
  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
    id: map['id'] as int,
    title: map['title'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    isOpen: (map['isOpen'] as int) == 1,
    listName: map['listName'] as String?,
  );

  // Helper: Convert to SQL map
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isOpen': isOpen ? 1 : 0,
    'listName': listName,
  };

  // Helper: Copy with for immutability
  NoteModel copyWith({int? id, String? title, DateTime? createdAt, DateTime? updatedAt, bool? isOpen, String? listName}) => NoteModel(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isOpen: isOpen ?? this.isOpen,
    listName: listName ?? this.listName,
  );
}

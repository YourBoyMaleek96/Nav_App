import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

/// DBHelper class that handles database operations using SQLite.
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  /// Returns the database instance.
  Future<Database> get database async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'notes.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            imagePaths TEXT,
            dateTime TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Inserts a note into the database.
  Future<int> insertNote(Note note) async {
    final dbClient = await database;
    return await dbClient.insert('notes', note.toMap());
  }

  /// Retrieves all notes from the database.
  Future<List<Note>> getNotes() async {
    final dbClient = await database;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'notes',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// Updates a note in the database.
  Future<int> deleteNote(int id) async {
    final dbClient = await database;
    return await dbClient.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
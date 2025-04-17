import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

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

  Future<int> insertNote(Note note) async {
    final dbClient = await database;
    return await dbClient.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final dbClient = await database;
    final List<Map<String, dynamic>> maps = await dbClient.query('notes', orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
}
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'waterborne.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT,
        email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_phone_number ON users(phone_number)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      return await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert user: $e');
    }
  }

  Future<User?> getUserByPhoneNumber(String phoneNumber) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'phone_number = ?',
        whereArgs: [phoneNumber],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get user: $e');
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get user by id: $e');
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('users');
      return List.generate(maps.length, (i) => User.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to get all users: $e');
    }
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    try {
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update user: $e');
    }
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete user: $e');
    }
  }

  Future<bool> userExists(String phoneNumber) async {
    final user = await getUserByPhoneNumber(phoneNumber);
    return user != null;
  }

  Future<User?> authenticateUser(String phoneNumber, String password) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'phone_number = ? AND password = ?',
        whereArgs: [phoneNumber, password],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to authenticate user: $e');
    }
  }

  // Database utility methods
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'waterborne.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Get database info for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final version = await db.getVersion();
    final path = db.path;
    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    ) ?? 0;

    return {
      'version': version,
      'path': path,
      'userCount': userCount,
    };
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

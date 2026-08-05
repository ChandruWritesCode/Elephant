import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('secure_chat.db');
    return _database!;
  }

  Future<String> _getEncryptionKey() async {
    const keyName = 'db_encryption_key';
    String? key = await _secureStorage.read(key: keyName);

    if (key == null) {
      final secureKey = base64Url.encode(List<int>.generate(32, (i) => i + 1));
      await _secureStorage.write(key: keyName, value: secureKey);
      key = secureKey;
    }
    return key;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    final password = await _getEncryptionKey();

    return await openDatabase(
      path,
      version: 1,
      password: password,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_read INTEGER NOT NULL,
        reply_to_id TEXT,
        sync_status TEXT NOT NULL -- 'synced' or 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE action_queue (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL, -- e.g., 'send_message', 'read_receipt'
        payload TEXT NOT NULL,     -- JSON string of the data
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE inbox (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        username TEXT,
        last_message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_group INTEGER NOT NULL,
        is_read INTEGER NOT NULL,
        unread_count INTEGER DEFAULT 0,
        last_message_sender TEXT,
        last_message_sync_status TEXT, -- MUST BE ADDED
        last_message_is_read INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members (
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        display_name TEXT,
        PRIMARY KEY (group_id, user_id)
      )
    ''');
  }

  Future<void> insertMessage(Map<String, dynamic> messageData) async {
    final db = await instance.database;
    await db.insert(
      'messages',
      messageData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> queueAction(
    String id,
    String type,
    Map<String, dynamic> payload,
  ) async {
    final db = await instance.database;
    await db.insert('action_queue', {
      'id': id,
      'action_type': type,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

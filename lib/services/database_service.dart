import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';
// import '../models/chat_message.dart';

class DatabaseService {
  static Database? _database;

  Future<void> init() async {
    if (_database != null) return;

    _database = await openDatabase(
      join(await getDatabasesPath(), 'hopntask.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            total REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            imagePath TEXT,
            ocrText TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'hopntask.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            total REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            imagePath TEXT,
            ocrText TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Receipt operations
  Future<void> insertReceipt(Receipt receipt) async {
    final db = await database;
    await db.insert(
      'receipts',
      {
        ...receipt.toJson(),
        'extractedData': jsonEncode(receipt.extractedData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('receipts');
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['extractedData'] = jsonDecode(map['extractedData'] as String);
      return Receipt.fromJson(map);
    });
  }

  Future<void> deleteReceipt(String id) async {
    final db = await database;
    await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat Methods
  Future<void> addMessage({
    required String message,
    required bool isUser,
  }) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        'message': message,
        'isUser': isUser ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllChatMessages() async {
    final db = await database;
    return await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );
  }

  Stream<List<Map<String, dynamic>>> getMessages() async* {
    final db = await database;
    yield* db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    ).asStream();
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_messages');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('categories');
    await db.delete('chat_messages');
  }

  // Export operations
  Future<String> exportToJson() async {
    final receipts = await getAllReceipts();
    final messages = await getAllChatMessages();
    
    final data = {
      'receipts': receipts.map((r) => r.toJson()).toList(),
      'chat_messages': messages,
    };
    
    return jsonEncode(data);
  }

  Future<String> exportToCsv() async {
    final receipts = await getAllReceipts();
    final buffer = StringBuffer();
    
    // Write header
    buffer.writeln('ID,Vendor,Total,Date,Category,ImagePath');
    
    // Write data
    for (final receipt in receipts) {
      buffer.writeln(
        '${receipt.id},'
        '${receipt.vendor},'
        '${receipt.total},'
        '${receipt.date.toIso8601String()},'
        '${receipt.category},'
        '${receipt.imagePath}',
      );
    }
    
    return buffer.toString();
  }

  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addExpense({
    required String title,
    required double total,
    required String category,
    String? imagePath,
    String? ocrText,
  }) async {
    final db = await database;
    await db.insert(
      'expenses',
      {
        'title': title,
        'total': total,
        'category': category,
        'date': DateTime.now().toIso8601String(),
        'imagePath': imagePath,
        'ocrText': ocrText,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return db.query(
      'expenses',
      orderBy: 'date DESC',
    );
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final results = await db.query(
      'expenses',
      distinct: true,
      columns: ['category'],
    );

    return results.map((row) => row['category'] as String).toList();
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 
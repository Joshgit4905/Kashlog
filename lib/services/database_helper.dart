import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/transaction.dart';
import '../models/planned_payment.dart';
import 'log_stream_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      var databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'kashlog.db',
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), 'kashlog.db');
      return await openDatabase(
        path,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        type TEXT,
        category TEXT,
        date TEXT,
        description TEXT,
        originalAmount REAL,
        originalCurrency TEXT,
        exchangeRate REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE planned_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        dueDate TEXT,
        isPaid INTEGER,
        category TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT UNIQUE,
        limit_amount REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE savings_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        target_amount REAL,
        current_amount REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT UNIQUE,
          limit_amount REAL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN originalAmount REAL',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN originalCurrency TEXT',
      );
      await db.execute('ALTER TABLE transactions ADD COLUMN exchangeRate REAL');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE savings_goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE,
          target_amount REAL,
          current_amount REAL
        )
      ''');
    }
  }

  // Transaction Methods
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    LogStreamService.log(
      '[DB] Query: INSERT INTO transactions (type: ${transaction.type}, amount: ${transaction.amount})',
    );
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    LogStreamService.log('[DB] Query: DELETE FROM transactions WHERE id = $id');
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTransactions() async {
    final db = await database;
    return await db.delete('transactions');
  }

  // Planned Payment Methods
  Future<int> insertPlannedPayment(PlannedPaymentModel payment) async {
    final db = await database;
    LogStreamService.log(
      '[DB] Query: INSERT INTO planned_payments (title: ${payment.title}, amount: ${payment.amount})',
    );
    return await db.insert('planned_payments', payment.toMap());
  }

  Future<List<PlannedPaymentModel>> getPlannedPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'planned_payments',
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) {
      return PlannedPaymentModel.fromMap(maps[i]);
    });
  }

  Future<int> deletePlannedPayment(int id) async {
    final db = await database;
    LogStreamService.log(
      '[DB] Query: DELETE FROM planned_payments WHERE id = $id',
    );
    return await db.delete(
      'planned_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePlannedPaymentStatus(int id, bool isPaid) async {
    final db = await database;
    LogStreamService.log(
      '[DB] Query: UPDATE planned_payments SET isPaid = ${isPaid ? 1 : 0} WHERE id = $id',
    );
    return await db.update(
      'planned_payments',
      {'isPaid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget Methods
  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    return await db.query('budgets');
  }

  Future<void> setBudget(String category, double limit) async {
    final db = await database;
    await db.insert('budgets', {
      'category': category,
      'limit_amount': limit,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Category Prediction Methods
  Future<String?> getMostUsedCategory(String description) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT category, COUNT(category) as count 
      FROM transactions 
      WHERE description LIKE ? 
      GROUP BY category 
      ORDER BY count DESC 
      LIMIT 1
    ''',
      ['%$description%'],
    );

    if (result.isNotEmpty) {
      return result.first['category'] as String?;
    }
    return null;
  }

  // Savings Goal Methods
  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final db = await database;
    return await db.query('savings_goals');
  }

  Future<void> updateSavingsGoal(
    String name,
    double target,
    double current,
  ) async {
    final db = await database;
    await db.insert('savings_goals', {
      'name': name,
      'target_amount': target,
      'current_amount': current,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

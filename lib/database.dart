import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._private();
  static Database _database;

  DatabaseHelper._private();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if(_database != null) {
      return _database;
    }

    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    var databasePath = join(await getDatabasesPath(), 'main.db');
    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE test(id INTEGER PRIMARY KEY, name TEXT)'
        );
      }
    );
  }
}

class TestObject {
  
  TestObject();

  Future<void> insert() async {
    var database = await DatabaseHelper().database;
    database.transaction((txn) async {
      txn.execute('INSERT INTO test(name) VALUES (?)', ['anmol']);
    });
  }

  Future<void> printNames() async {
    var database = await DatabaseHelper().database;
    var names = await database.rawQuery('SELECT * FROM test');
    var nameList = names.map((e) => e['name']).toList();
    print(nameList);
  }
}
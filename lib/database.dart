import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:convert/convert.dart';

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
        db.execute('CREATE TABLE devices_seen(id INTEGER PRIMARY KEY, device_id BLOB UNIQUE)');
      }
    );
  }

  Future<void> resetDatabase() async {
    var databasePath = join(await getDatabasesPath(), 'main.db');
    await deleteDatabase(databasePath);
  }
}

class DevicesSeen {
  final Uint8List deviceId;

  DevicesSeen(this.deviceId);

  addToDatabase() async {
    var database = await DatabaseHelper().database;
    try {
      await database.insert('devices_seen', {'device_id' : deviceId});
    } catch(e) {
      print("error");
    }
  }
}

class SuspectedDevice {
  final String deviceId;
  final bool diagnosedOrSuspected;

  SuspectedDevice(this.deviceId, this.diagnosedOrSuspected);

  addToDatabase() async {
    var database = await DatabaseHelper().database;
    database.transaction((txn) async {
      txn.rawInsert('INSERT INTO devices_susp(device_id, diag_or_susp) VALUES (?,?)', 
        [hex.decode(deviceId), diagnosedOrSuspected ? 1 : 0]);
    });
  }
}
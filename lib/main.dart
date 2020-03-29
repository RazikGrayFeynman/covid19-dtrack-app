import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class DatabaseHelper {
  static final DatabaseHelper _databaseHelper = DatabaseHelper._internal();
  static Database _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _databaseHelper;
  }

  Future<Database> get database async {
    _database = await _init();
    return _database;
  }

  Future<Database> _init() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'main.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE Cases (id INTEGER PRIMARY KEY, mac TEXT UNIQUE, diag INTEGER)');
        await db.execute('CREATE TABLE Seen (id INTEGER PRIMARY KEY, mac TEXT UNIQUE)');
      }
    );
  }

  Future<void> reset() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'main.db');
    await deleteDatabase(path);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE test',
      home: Scaffold(
        appBar: AppBar(title: Text('ble test')),
        body: Column(
          children: <Widget>[
            DevicesSeenPanel(),
          ],
        )
      )
    );
  }
}

class DevicesSeenPanel extends StatefulWidget {
  _DevicesSeenState createState() => _DevicesSeenState();
}

class _DevicesSeenState extends State<DevicesSeenPanel> {
  List<String> devices = [];
  String status = 'Idle';
  String interactionStatus = 'Not yet computed';
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RaisedButton(
          child: Text('Reset local datbase'),
          onPressed: resetDb
        ),
        RaisedButton(
          child: Text('Update seen devices'), 
          onPressed: updateDevices
        ),
        RaisedButton(
          child: Text('View seen devices'),
          onPressed: viewSeenDevices
        ),
        Center(
          child: Text('Status: ' + status)
        ),
        Container(
          height: 256,
          color: Colors.grey[100],
          child: ListView(
            children: devices.map((e) => Padding(child: Center(child: Text(e)), padding: EdgeInsets.all(8))).toList()
          )
        ),
        RaisedButton(
          child: Text('Update known cases'),
          onPressed: updateKnownCases
        ),
        RaisedButton(
          child: Text('Check interaction status'),
          onPressed: checkInteractionStatus
        ),
        Center(
          child: Text(interactionStatus)
        )
      ]
    );
  }
  
  Future<void> viewSeenDevices() async {
    var db = await DatabaseHelper().database;
    var seenDevices = await db.rawQuery('SELECT * FROM Seen');
    var seenDevicesNames = seenDevices.map((e) => e['mac'].toString());
    setState(() => devices = seenDevicesNames.toList());
  }

  Future<void> updateDevices() async {
    var db = await DatabaseHelper().database;
    setState(() => status = 'Updating ...');
    var _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) async {
      await db.transaction((txn) async {
        try {
          int id1 = await txn.rawInsert('INSERT INTO Seen(mac) VALUES(?)', [r.device.address]);
          print('inserted $id1');
        } catch (e) {
          print('already exists');
        }
      });
    });

    _streamSubscription.onDone(() {
      _streamSubscription.cancel();
      setState(() => status = 'Idle');
      print("done");
      viewSeenDevices();
      }
    );
  }

  Future<void> resetDb() async {
    DatabaseHelper().reset();
    setState(() => interactionStatus = 'Not yet computed');
    await viewSeenDevices();
  }

  Future<void> updateKnownCases() async {
    setState(() => status = 'Updating ...');
    var db = await DatabaseHelper().database;
    var url = 'https://arctic-thunder.herokuapp.com/cases';
    var resp = await http.get(url);
    Map<String, dynamic> body = jsonDecode(resp.body);
    
    await db.transaction((txn) async {await txn.rawDelete('DELETE FROM Cases');});
    body['cases'].forEach((e) async {
      await db.transaction((txn) async {
        try {
          int id = await txn.rawInsert('INSERT INTO Cases(mac,diag) VALUES(?,?)', [e['mac'], e['diag_or_susp'] ? 1 : 0]);
        } catch(e) {
          print("exists");
        }
      });
    });
    setState(() => status = 'Idle');
  }

  Future<void> checkInteractionStatus() async {
    var db = await DatabaseHelper().database;
    var suspCases = await db.rawQuery('SELECT mac from Cases where diag = 0');
    var confCases = await db.rawQuery('SELECT mac from Cases where diag = 1');

    var confInteraction = false;
    // Check for confirmed cases first
    for(final c in confCases) {
      var seenCases = await db.rawQuery('SELECT mac from Seen where mac = ?', [c['mac']]);
      if (seenCases.length > 0) {
        confInteraction = true;
        break;
      }
    }

    if (confInteraction) {
      setState(() => interactionStatus = 'Possible interaction with confirmed case');
      return;
    }

    var suspInteraction = false;
    // Check for suspected cases next
    for(final c in suspCases) {
      var seenCases = await db.rawQuery('SELECT mac from Seen where mac = ?', [c['mac']]);
      if (seenCases.length > 0) {
        suspInteraction = true;
        break;
      }
    }

    if (suspInteraction) {
      setState (() => interactionStatus = 'Possible interaction with suspected case');
      return;
    }

    setState(() => interactionStatus = 'Not interacted with any potential cases');
  }
}
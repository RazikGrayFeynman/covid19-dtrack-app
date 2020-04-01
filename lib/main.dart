import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services.dart';
import 'database.dart';
import 'package:http/http.dart' as http;

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/' : (BuildContext context) => HomePage(),
      }
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _firstTime;
  bool _loggedIn;

  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var prefs = await SharedPreferences.getInstance();
      var firstTime;
      var loggedIn;

      if(prefs.getBool('firstTime') == null || prefs.getBool('firstTime') == true) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => SplashPage()));
        firstTime = false;
        prefs.setBool('firstTime', false);
      } else {
        firstTime = prefs.getBool('firstTime');
      }

      if(prefs.getBool('loggedIn') == null || prefs.getBool('loggedIn') == false) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
        loggedIn = true;
        prefs.setBool('loggedIn', true);
      } else {
        loggedIn = prefs.getBool('loggedIn');
      }

      setState(() {
        _firstTime = firstTime;
        _loggedIn = loggedIn;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_firstTime == null && _loggedIn == null) {
      return SpinnerPage();
    }

    if(_firstTime) {
      return SplashPage();
    }

    if(!_loggedIn) {
      return LoginPage();
    }

    return DashboardPage();
  }
}

class CheckExposurePage extends StatefulWidget {
  CheckExposurePageState createState() => CheckExposurePageState();
}

class CheckExposurePageState extends State<CheckExposurePage> {
  bool _loading = true;
  String _progressMessage = 'Downloading data ...';
  String _finalMessage = 'Analyzing...';

  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) async {
      var database = await DatabaseHelper().database;
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('access_token');
      var resp = await http.get('https://arctic-thunder.herokuapp.com/cases', headers: {'Authorization' : 'Bearer $token'});
      setState(() => _progressMessage = 'Testing cases');
      var cases = json.decode(resp.body)['cases'];
      var diagOrSusp;
      var contactFound = false;
      for(var c in cases) {
        var deviceId = c['device_id'];
        var res = await database.rawQuery('SELECT * FROM devices_seen WHERE device_id = X\'$deviceId\'');

        if (res.length > 0) {
          contactFound = true;
          diagOrSusp = c['diag_or_susp'];

          if(diagOrSusp) {
            break;
          }
        }
      }

      setState(() {
        _loading = false;
        _progressMessage = 'Completed analysis';
        _finalMessage = 'Based on the data, your status is: \n\n' + 
        (!contactFound ? 'No contact with suspected case' : 
        diagOrSusp ? 'Contact with diagnosed case' : 'Contact with suspected case');
      });
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check My Exposure', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Center(child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(32), 
            child: Center(
              child: Container(
                height: 100, 
                width: 100, 
                child: _loading ? CircularProgressIndicator() : Icon(Icons.check, color: Colors.green, size: 72)))),
          Center(child: Text(_progressMessage, style: TextStyle(fontSize:24))),
          Padding(padding: EdgeInsets.all(16), child: FractionallySizedBox(
            widthFactor: 0.8, 
            child: Container(
              height: 200, 
              child: Card(child: Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(_finalMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 18))))))))
        ]
      )
    ));
  }
}

class SpinnerPage extends StatelessWidget {
  Widget build(BuildContext buildContext) {
    return Scaffold(
      body: Center(child: Text('Loading...'))
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.5,
        child: Container(
          child: Column(
            children: <Widget>[
              RaisedButton(child: Text('Login'), onPressed: () async {
                var prefs = await SharedPreferences.getInstance();
                prefs.setBool('loggedIn', true);
                prefs.setBool('firstTime', false);

                var resp = await http.post('https://arctic-thunder.herokuapp.com/auth');
                var respJson = json.decode(resp.body);
                prefs.setString('access_token', respJson['access_token']);
                prefs.setString('device_id', respJson['device_id']);
                Navigator.pop(context);
              })
            ]
          )
        )
      ))
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  @override
  initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var servicesManager = ServiceManager();
      try {
        await servicesManager.startAllServices();
      } on PlatformException catch(e) {
        print(e);
      }
    });
  super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('COVID19 DTrack', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    child: Card(
                      child: Center(child: Text('No new notifications'))
                    ),
                    padding: EdgeInsets.all(8)
                  )
                ),
                Padding (padding: EdgeInsets.all(12), child: RaisedButton(
                  color: Colors.blue,
                  onPressed: () async {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CheckExposurePage()));
                  }, 
                  child: Text('Check my exposure', style:  TextStyle(color: Colors.white, fontSize: 18)))),
                
              ],
              crossAxisAlignment: CrossAxisAlignment.stretch
            ),
            height: 200
          ),
          Expanded(
            child: GridView.count(
              padding: EdgeInsets.all(8),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              crossAxisCount: 2,
              children: <Widget>[
                MainGridElement('Services Status', StatusPage(), Icons.bluetooth, Colors.grey),
                MainGridElement('Data Stored', DataStoragePage(), Icons.archive, Colors.grey),
                MainGridElement('About', DummyPage(), Icons.info, Colors.grey),
                MainGridElement('Help!', DummyPage(), Icons.help, Colors.grey),
              ]
            )
          ),
        ]
      )
    );
  }
}

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.75,
        child: Container(
          child: Column(
            children: <Widget>[
              Padding(child: Text('COVID19 DTrack', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), padding: EdgeInsets.only(top: 16)),
              Padding(child: Text('The privacy-preserving app for tracking cases'), padding: EdgeInsets.all(4)),
              Padding(
                child: Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(child: Text('Overview of app'))
                ),
                padding: EdgeInsets.all(24)
              ),
              RaisedButton(child: Text('Get Started'), onPressed: () async {
                Navigator.pop(context);
              })
            ]
          )
        )
      ))
    );
  }
}

class StatusPage extends StatefulWidget {
  @override
  StatusPageState createState() => StatusPageState();
}

class StatusPageState extends State<StatusPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(child: Text('Bluetooth', style: TextStyle(fontSize: 18)), padding: EdgeInsets.all(16)),
                FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder: (BuildContext context, AsyncSnapshot<SharedPreferences> data) {
                    return Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 16),
                      child: !data.hasData ? Text('Device ID : Loading...') : Text('Device ID : ' + data.data.getString('device_id') ?? 'Not inited')
                    );
                  } 
                )
              ]
            )
          )
        ]
      )
    );
  }
}

class DataStoragePage extends StatefulWidget {
  @override
  DataStoragePageStatus createState() => DataStoragePageStatus();
}

class DataStoragePageStatus extends State<DataStoragePage> {
  int _numDevices = 0;

  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) async {
      var database = await DatabaseHelper().database;
      var numDevices = (await database.rawQuery('SELECT COUNT(*) FROM devices_seen'))[0]['COUNT(*)'];
      setState (() => _numDevices = numDevices);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Stored', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(child: Text('Bluetooth', style: TextStyle(fontSize: 18)), padding: EdgeInsets.all(16)),
                Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 16),
                  child: Text('Number of devices seen : ' + _numDevices.toString())
                )
              ]
            )
          )
        ]
      )
    );
  }
}

class MainGridElement extends StatelessWidget {
  final String title;
  final Widget route;
  final IconData icon;
  final Color color;

  MainGridElement(this.title, this.route, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        child: Column(
          children: <Widget>[
            Expanded(child: Icon(icon, size: 56, color: color)),
            Padding(padding: EdgeInsets.all(12), child: Text(title)),
          ]
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => route));
        }
      )
    );
  }
}

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dummy page', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Center(child: Text('Dummy page'))
    );
  }
}
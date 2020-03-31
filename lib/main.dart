import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/' : (BuildContext context) => HomePage(),
        '/status' : (BuildContext context) => StatusPage(),
      }
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return DashboardPage();
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
                Navigator.pushReplacementNamed(context, '/');
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
                  onPressed: () => print("lol"), 
                  child: Text('Check my exposure', style:  TextStyle(color: Colors.white, fontSize: 18))))
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
                MainGridElement('Services Status', '/status', Icons.bluetooth, Colors.grey),
                MainGridElement('Data Stored', '/status', Icons.archive, Colors.grey),
                MainGridElement('About', '/status', Icons.info, Colors.grey),
                MainGridElement('Help!', '/status', Icons.help, Colors.grey),
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
                Navigator.pushReplacementNamed(context, '/login');
              })
            ]
          )
        )
      ))
    );
  }
}

class StatusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.grey
      ),
      body: Center(child: Text('Services status'))
    );
  }
}

class MainGridElement extends StatelessWidget {
  final String title;
  final String route;
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
          Navigator.pushNamed(context, route);
        }
      )
    );
  }
}
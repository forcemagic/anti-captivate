import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'guide.dart' as guide;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntiCaptivate ⚡',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Color.fromARGB(255,25,25,25),
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'AntiCaptivate ⚡'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showLog = false;
  String status = "Please wait! I'm loading! 🕒";
  List<String> log = List<String>();

  @override
  void initState() {
    guide.entry((String state) => {
      this.setState(() {
        this.status = state;
        this.log.insert(0, DateFormat('H:m:s: ').format(DateTime.now()) + state);
      }),
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(onPressed: () {
            this.setState(() { this.showLog = !this.showLog; });
          }, tooltip: 'Show/Hide Logs', icon: Icon(showLog ? Icons.visibility_off : Icons.visibility)),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(12),
              child: Text(status, style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            ),
            (showLog ? Expanded(
              child: ListView.builder(itemBuilder: (BuildContext bc, int i) => Text(log[i]), itemCount: log.length),
            ) : Container()),
          ],
        ),
      ),
    );
  }
}

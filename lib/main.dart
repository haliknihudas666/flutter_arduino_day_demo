import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/pages/devices.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gift Box Controller',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const DevicesPage(),
    );
  }
}

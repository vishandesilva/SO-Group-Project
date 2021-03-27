import 'package:flutter/material.dart';
import 'package:novus/pages/HomePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// root widget for the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Novus',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        dialogBackgroundColor: Colors.grey,
        iconTheme: IconThemeData(color: Colors.blue),
        primarySwatch: Colors.purple,
        hintColor: Colors.blue,
        cardColor: Colors.blue,
        accentColor: Colors.blue,
        buttonColor: Colors.blue,
        dividerColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

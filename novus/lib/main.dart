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
        primarySwatch: createMaterialColor(Color(0xff272091)),
        hintColor: Colors.blue,
        cardColor: Colors.blue,
        accentColor: createMaterialColor(Color(0xff1A88C9)),
        buttonColor: Colors.blue,
        dividerColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }

  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(color.value, swatch);
  }
}

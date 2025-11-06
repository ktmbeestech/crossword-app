import 'package:crosswords/modules/landing/screens/landing.shell.page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class App extends StatelessWidget {
  const App({super.key});



  @override
  Widget build(BuildContext context) {
        return MainApp();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: "CROSSWORDS",
        theme: ThemeData(),
        home: CrosswordLandingPage(),
    );
  }
}

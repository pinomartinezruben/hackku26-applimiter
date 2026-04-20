// import all the packages fot the materials needed for flutter development
import 'package:flutter/material.dart';
// main_page is the home page of our application, so we start the app there
import 'package:hackku_applimiter/main_page.dart';

// main function starts the app
void main() {
  // 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: true,
      home: MainPage(),
    );
  }
}

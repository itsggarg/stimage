import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St🪡mage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(loggedInUser: 'Guest User'), // Start with HomePage
    );
  }
}
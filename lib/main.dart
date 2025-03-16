import 'package:flutter/material.dart';
import 'package:mini_projet/neworking_api/dio_helper.dart';
import 'package:mini_projet/screens/home_screen.dart';

void main() async {
  DioHelper.initDio();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeScreen(),
    );
  }
}

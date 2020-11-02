import 'package:flutter/material.dart';
import 'package:tflite_popular_wine_classifier/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TFLite Popular Wine Classifier',
      theme: ThemeData(
      ),
      home: MainPage(),
    );
  }
}

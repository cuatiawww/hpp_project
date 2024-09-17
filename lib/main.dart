import 'package:flutter/material.dart';
import 'package:hpp_project/pages/home_page.dart';
// import 'dart:io';

// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // // Inisialisasi sqflite_ffi
  // sqfliteFfiInit();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

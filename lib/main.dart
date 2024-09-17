import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/pages/home_page.dart';
import 'package:hpp_project/pages/pers_awal.dart';
// import 'dart:io';

// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: PersAwal(),
    );
  }
}

import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Error: Bad state: databaseFactory not initialized databaseFactory is only initialized when using sqflite. When using sqflite_common_ffi You must call databaseFactory = databaseFactoryFfi; before using global openDatabase API',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

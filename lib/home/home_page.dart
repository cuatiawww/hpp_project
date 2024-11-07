import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/home/components/bottom_nav_bar.dart';
import 'package:hpp_project/home/components/custom_app_bar.dart';
import 'package:hpp_project/home/components/pers_awal_content.dart';
import 'package:hpp_project/laporan_page.dart';
import 'package:hpp_project/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final authC = Get.find<AuthController>();
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _initAuthStateListener();
  }

  void _initAuthStateListener() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _initializeControllers(user);
      }
    });
  }

  void _initializeControllers(User user) {
    Get.delete<DataPribadiController>();
    Get.delete<DataUsahaController>();
    final dataPribadiC = Get.put(DataPribadiController(uid: user.uid), tag: user.uid);
    final dataUsahaC = Get.put(DataUsahaController(uid: user.uid), tag: user.uid);
    dataPribadiC.fetchDataPribadi(user.uid);
    dataUsahaC.fetchDataUsaha(user.uid);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    PersAwalContent(),
    LaporanPage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
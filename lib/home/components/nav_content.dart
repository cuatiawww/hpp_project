import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/home/components/clip_path.dart';
import 'package:hpp_project/home/components/laporan_section.dart';
import 'package:hpp_project/home/components/menu_section.dart';
import 'package:hpp_project/home/components/profile_card.dart';
import 'package:hpp_project/home/components/riwayat_section.dart';

class PersAwalContent extends StatefulWidget {
  @override
  State<PersAwalContent> createState() => _PersAwalContentState();
}

class _PersAwalContentState extends State<PersAwalContent> {
  late DataPribadiController dataPribadiC;
  late DataUsahaController dataUsahaC;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  void initializeControllers() {
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      dataPribadiC = Get.put(DataPribadiController(uid: currentUser.uid), tag: currentUser.uid);
      dataUsahaC = Get.put(DataUsahaController(uid: currentUser.uid), tag: currentUser.uid);
      loadUserData();
    }
  }

  Future<void> loadUserData() async {
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      try {
        await dataPribadiC.fetchDataPribadi(currentUser.uid);
        await dataUsahaC.fetchDataUsaha(currentUser.uid);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: ClipPathClass(),
          child: Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            color: Color(0xFF080C67),
          ),
        ),
        SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                ProfileCard(),
                SizedBox(height: 24),
                MenuSection(),
                SizedBox(height: 24),
                LaporanSection(),
                SizedBox(height: 24),
                RiwayatSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
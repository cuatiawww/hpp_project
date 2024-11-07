// lib/pages/home/components/profile_card.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';

class ProfileCard extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.currentUser;
  
    if (currentUser == null) {
      return Center(child: Text('Silakan login terlebih dahulu'));
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF080C67),
                  Color(0xFF1E23A7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        "assets/images/shop.png",
                        height: 24,
                        width: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GetX<DataUsahaController>(
                        tag: currentUser.uid,
                        builder: (controller) => Text(
                          controller.namaUsaha.value.isEmpty 
                              ? 'Memuat...' 
                              : controller.namaUsaha.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                GetX<DataUsahaController>(
                  tag: currentUser.uid,
                  builder: (controller) => RichText(
                    text: TextSpan(
                      text: "Tipe Usaha: ",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: controller.tipeUsaha.value.isEmpty 
                              ? 'Memuat...' 
                              : controller.tipeUsaha.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Divider(color: Colors.white.withOpacity(0.2)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GetX<DataUsahaController>(
                        tag: currentUser.uid,
                        builder: (controller) => RichText(
                          text: TextSpan(
                            text: "Nomor Telepon: ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: controller.nomorTelepon.value.isEmpty 
                                    ? 'Memuat...' 
                                    : controller.nomorTelepon.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
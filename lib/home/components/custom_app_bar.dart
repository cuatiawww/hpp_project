// lib/pages/home/components/custom_app_bar.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Color(0xFF080C67),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                currentUser != null ? GetX<DataPribadiController>(
                  tag: currentUser.uid,
                  builder: (controller) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hello,",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        controller.namaLengkap.value.isEmpty 
                            ? 'Loading...' 
                            : controller.namaLengkap.value + "!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ) : Text("Welcome, Guest"),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFF080C67),
      elevation: 0,
    );
  }
}
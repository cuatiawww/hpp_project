// lib/pages/home/components/custom_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpp_project/routes/routes.dart';

class CustomHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF080C67),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentUser != null)
                GetX<DataPribadiController>(
                  tag: currentUser.uid,
                  init: DataPribadiController(uid: currentUser.uid),
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
                            : "${controller.namaLengkap.value}!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  "Welcome, Guest",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),

              // Icon Notifikasi dengan StreamBuilder
              if (currentUser != null)
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser.uid)
                      .collection('Notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    bool hasUnreadNotifications =
                        snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                    return IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 36,
                          ),
                          if (hasUnreadNotifications)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        // Navigasi ke halaman notifikasi
                        Get.toNamed(Routes.notif);
                      },
                    );
                  },
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: () {
                    Get.toNamed(Routes.notif);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

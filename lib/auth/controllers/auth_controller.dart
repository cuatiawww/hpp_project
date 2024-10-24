import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/routes/routes.dart';

class AuthController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> get streamAuthStatus => auth.authStateChanges();

  void login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text("Login Berhasil"),
        ),
      );
      Get.offAllNamed(Routes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  void signup(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            "Akun berhasil dibuat!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.greenAccent[400],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // await auth.sendEmailVerification();
        // Get.defaultDialog(
        //   title: "Akun berhasil dibuat",
        //   middleText: "Kami telah mengirimkan email verifikasi ke $email",
        //   onConfirm: () {
        //     Get.back(); // Close the dialog
        //     Get.back(); // Go to login page
        //   },
        //   textConfirm: "Lanjut",
      );
      Get.offAllNamed(Routes.login);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Password yang digunakan terlalu lemah');
      } else if (e.code == 'email-already-in-use') {
        print('Akun dengan email ini sudah terdaftar.');
      }
    } catch (e) {
      print(e);
    }
  }

  void resetPassword(String email) async {
    if (email != "" && GetUtils.isEmail(email)) {
      try {
        await auth.sendPasswordResetEmail(email: email);
        Get.defaultDialog(
          title: "Berhasil reset password!",
          middleText: "Kami telah mengirimkan email ke $email",
          onConfirm: () {
            Get.back(); // Close the dialog
            Get.back(); // Go to login page
          },
          textConfirm: "Lanjut",
        );
      } catch (e) {
        Get.defaultDialog(
          title: "Terjadi Kesalahan",
          middleText: "Tidak dapat mengirimkan email. Coba lagi.",
        );
      }
    } else {
      Get.defaultDialog(
        title: "Terjadi Kesalahan",
        middleText: "Email tidak valid.",
      );
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.login);
  }
}

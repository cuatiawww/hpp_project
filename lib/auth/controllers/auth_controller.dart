import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/routes/routes.dart';

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function untuk mendapatkan UID pengguna yang sedang aktif
  String? get currentUserId => auth.currentUser?.uid;

  Stream<User?> get streamAuthStatus => auth.authStateChanges();

  // Function untuk membuat akun user
  Future<void> signup(String email, String password) async {
    try {
       // Sign up user dengan email & password
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Mengambil UID dari user yang berhasil sign-up
      String uid = userCredential.user?.uid ?? '';

      // Simpan data awal ke Firestore dengan UID sebagai document ID
      await _firestore.collection('Users').doc(uid).set({
        'email': email,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Menampilkan pesan sukses pendaftaran
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
      );
      Get.offAllNamed(Routes.infoScreen, arguments: uid); // Gunakan UID yang didapat dari pendaftaran
    } on FirebaseAuthException catch (e) {
      print('Error code: $e.code');
      print('Error message: $e.message');
      String errorMessage = '';
      if (e.code == 'weak-password') {
        errorMessage = 'Password yang digunakan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Akun dengan email ini sudah terdaftar.';
      }
      // Tampilkan pesan kesalahan jika ada
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(errorMessage,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  // Function untuk login user
  Future<void> login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            "Login Berhasil!",
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
      );
      Get.offAllNamed(Routes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Get.snackbar(
          'Akun tidak ditemukan',
          'Email tidak terdaftar',
          backgroundColor: Colors.redAccent,
        );
      } else if (e.code == 'wrong-password') {
        Get.snackbar(
          'Password yang diberikan salah',
          'Silahkan coba lagi',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  // Function untuk reset password
  Future<void> resetPassword(String email) async {
    if (email.isNotEmpty && GetUtils.isEmail(email)) {
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

  // Function untuk logout
  Future<void> logout() async {
    await auth.signOut();
    Get.offAllNamed(Routes.login);
  }
}


// Untuk mengirim email verifikasi pada function signup
// await auth.sendEmailVerification();
        // Get.defaultDialog(
        //   title: "Akun berhasil dibuat",
        //   middleText: "Kami telah mengirimkan email verifikasi ke $email",
        //   onConfirm: () {
        //     Get.back(); // Close the dialog
        //     Get.back(); // Go to login page
        //   },
        //   textConfirm: "Lanjut",
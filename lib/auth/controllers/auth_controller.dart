import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';
import 'package:hpp_project/routes/routes.dart';
import 'package:email_validator/email_validator.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   
  Timer? emailVerificationTimer;
  final isEmailVerified = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get streamAuthStatus => _auth.authStateChanges();

   @override
  void onInit() {
    super.onInit();
    // Check if user is already verified when app starts
    checkEmailVerificationStatus();
  }

  Future<void> signup(String email, String password) async {
    try {
      if (!EmailValidator.validate(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Format email tidak valid.',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
      });

      Get.offAllNamed(Routes.verifyEmail);
      startEmailVerificationTimer();

      showSnackBar('Registrasi berhasil! Silakan verifikasi email Anda', isError: false);

    } catch (e) {
      String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'Format email tidak valid';
            break;
          case 'email-already-in-use':
            errorMessage = 'Email sudah terdaftar';
            break;
          case 'weak-password':
            errorMessage = 'Password terlalu lemah';
            break;
        }
      }
      showSnackBar(errorMessage, isError: true);
    }
  }

  void startEmailVerificationTimer() {
    // Cancel any existing timer
    emailVerificationTimer?.cancel();
    
    // Check every 3 seconds
    emailVerificationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerificationStatus(),
    );
  }

  Future<void> checkEmailVerificationStatus() async {
    final user = _auth.currentUser;
    
    if (user != null) {
      // Reload user to get latest status
      await user.reload();
      
      if (user.emailVerified) {
        isEmailVerified.value = true;
        emailVerificationTimer?.cancel();
        
        // Update Firestore
        await _firestore.collection('Users').doc(user.uid).update({
          'isEmailVerified': true,
        });
        
        // Navigate to info screen after verification
        Get.offAllNamed(Routes.infoScreen);
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      await user?.sendEmailVerification();
      showSnackBar('Email verifikasi telah dikirim ulang!', isError: false);
    } catch (e) {
      showSnackBar('Gagal mengirim email verifikasi', isError: true);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        showSnackBar('Silakan verifikasi email Anda terlebih dahulu', isError: true);
        await _auth.signOut();
        return;
      }

      // Check if profile is completed
      final hasProfile = await checkProfileCompletion(userCredential.user!.uid);

      if (!hasProfile) {
      Get.offAllNamed(Routes.home);
      } else {
        Get.offAllNamed(Routes.infoScreen);
      }
      
      await addNotification(
        title: 'Login Berhasil',
        message: 'Anda telah berhasil login.',
      );
      showSnackBar('Login berhasil', isError: false);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage = 'Password salah';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        default:
          errorMessage = 'Gagal login. Silakan coba lagi.';
      }
      showSnackBar(errorMessage, isError: true);
    }
  }

  Future<bool> checkProfileCompletion(String uid) async {
    try {
      final personalDoc = await _firestore
          .collection('Users')
          .doc(uid)
          .collection('PersonalData')
          .doc('dataPribadi')
          .get();
          
      final businessDoc = await _firestore
          .collection('Users')
          .doc(uid)
          .collection('BusinessData')
          .doc('dataUsaha')
          .get();
          
      return personalDoc.exists && businessDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      if (EmailValidator.validate(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Format email tidak valid',
        );
      }
      await _auth.sendPasswordResetEmail(email: email);
      Get.defaultDialog(
        title: "Berhasil Reset Password!",
        middleText: "Kami telah mengirimkan email ke $email",
        onConfirm: () {
          Get.back();
          Get.back();
        },
        textConfirm: "Lanjut",
      );
    } catch (e) {
      showSnackBar('Gagal mengirim email reset password', isError: true);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(Routes.login);
      showSnackBar('Logout berhasil', isError: false);
    } catch (e) {
      showSnackBar('Gagal logout', isError: true);
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    if (Get.context == null) return;

    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(
          textAlign: TextAlign.center,
          message,
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600
          ),
        ),
        duration: Duration(seconds: 5),
        backgroundColor: isError ? Colors.red : Colors.greenAccent[400],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void onClose() {
    emailVerificationTimer?.cancel();
    super.onClose();
  }
}
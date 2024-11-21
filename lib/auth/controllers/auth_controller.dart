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
   
   // Function untuk mendapatkan UID pengguna yang sedang aktif
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get streamAuthStatus => _auth.authStateChanges();

  // Variable untuk menyimpan OTP sementara
  String? _tempEmail;
  String? _tempPassword;
  String? _verificationId;
  String? get tempEmail => _tempEmail;

  // FUNCTION SIGNUP USER
  Future<void> signup(String email, String password) async {
    try {
      if (!EmailValidator.validate(email)) { // Validasi email
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Format email tidak valid.',
        );
      }

      // Cek apakah email sudah terdaftar
      final emailCheck = await _auth.fetchSignInMethodsForEmail(email);
      if (emailCheck.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email sudah terdaftar',
        );
      }

      // Simpan credentials sementara
      _tempEmail = email;
      _tempPassword = password;

      // Cek apakah email valid dengan mencoba mengirim OTP
      await sendOTP(email);


      // Redirect ke halaman OTP
      Get.toNamed(Routes.otp);

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

  // FUNCTION LOGIN USER
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.offAllNamed(Routes.home);
      // Menambahkan notifikasi login berhasil
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
          errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      }
      showSnackBar(errorMessage, isError: true);
    }
  }

  // FUNCTION RESET PASSWORD USER
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
          Get.back(); // Close the dialog
          Get.back(); // Go to login page
        },
        textConfirm: "Lanjut",
      );
    } catch (e) {
      showSnackBar('Gagal mengirim email reset password', isError: true);
    }
  }

  // FUNCTION LOGOUT USER
  Future<void> logout() async {
    try{
      await _auth.signOut();
      Get.offAllNamed(Routes.login);
      showSnackBar('Logout berhasil', isError: false);
    } catch (e) {
      showSnackBar('Gagal logout', isError: true);
    }
  }

  // Fungsi untuk mengirim OTP ke email
   Future<void> sendOTP(String email) async {
    try {
      // Cek pengiriman OTP sebelumnya
      final otpCountRef = _firestore.collection('otp_logs').doc(email);
      final otpCountSnap = await otpCountRef.get();
      if (otpCountSnap.exists) {
        final data = otpCountSnap.data()!;
        final lastSent = (data['lastSent'] as Timestamp).toDate();
        final count = data['count'] ?? 0;

        if (DateTime.now().difference(lastSent).inHours < 24 && count >= 3) {
          throw Exception('Anda telah melebihi batas pengiriman OTP untuk hari ini.');
        }
      }

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://hpptaxcenter.page.link/verify',
          handleCodeInApp: true,
          androidPackageName: 'com.example.hpp_project',
          androidMinimumVersion: '12',
          dynamicLinkDomain: 'hpptaxcenter.page.link',
        ),
      );
      showSnackBar('Kode OTP telah dikirim ke email Anda', isError: false);
    } catch (e) {
      print('Error sending OTP: $e');
      throw Exception('Gagal mengirim OTP');
    }
  }

  // Fungsi untuk verifikasi OTP
  Future<void> verifyOTP(String otp) async {
    try {
      if (_tempEmail == null) {
        throw Exception('Email tidak valid');
      }

      final signInMethods = await _auth.fetchSignInMethodsForEmail(_tempEmail!);
      if (signInMethods.contains('password')) {
        throw Exception('Email sudah terdaftar');
      }

      // Create user after OTP verification
      await finalizeRegistration();

    } catch (e) {
      showSnackBar('Verifikasi OTP gagal: ${e.toString()}', isError: true);
    }
  }

  // Fungsi untuk memfinalisasi registrasi setelah OTP terverifikasi
  Future<void> finalizeRegistration() async {
    if (_tempEmail == null || _tempPassword == null) {
      showSnackBar('Data registrasi tidak valid', isError: true);
      return;
    }
    
    try {
      // Membuat user di Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _tempEmail!,
          password: _tempPassword!,
        );

      await userCredential.user?.sendEmailVerification();

      // Simpan data ke Firestore
      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'email': _tempEmail,
        'password': _tempPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
      });

       _clearTempData();
       // Arahkan ke halaman OTP Success
      Get.offAllNamed(Routes.otpSuccess);
      showSnackBar('Registrasi berhasil! Silakan verifikasi email Anda', isError: false);

    } catch (e) {
      showSnackBar('Gagal menyelesaikan registrasi', isError: true);
      print('Error in finalizeRegistration: $e');
    }
  }

  // Clear temporary data
  void _clearTempData() {
  _tempEmail = null;
  _tempPassword = null;
  _verificationId = null;
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
}
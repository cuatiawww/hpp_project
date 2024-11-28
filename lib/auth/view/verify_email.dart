import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class VerifyEmailPage extends StatelessWidget {
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Verifikasi Email Anda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Link verifikasi telah dikirim ke email Anda.\nSilakan cek email dan klik link verifikasi.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF080C67),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => authController.sendVerificationEmail(),
                child: Text(
                  'Kirim Ulang Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    authController.startEmailVerificationTimer(); // Mulai timer untuk mengecek status verifikasi
  }

  @override
  void dispose() {
    authController.emailVerificationTimer?.cancel(); // Batalkan timer saat halaman ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser;
    final email = user?.email ?? '';
    final maskedEmail = email.replaceRange(1, email.indexOf('@'), '*' * (email.indexOf('@') - 1));

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 100,
                          color: Color(0xFF3E63F4),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Verifikasi Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Link Verifikasi telah di kirim ke $maskedEmail',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tidak menerima kode?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF080C67),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            authController.sendVerificationEmail();
                          },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
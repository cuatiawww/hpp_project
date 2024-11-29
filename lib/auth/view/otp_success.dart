import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/routes/routes.dart';

class OtpSuccess extends StatelessWidget {
  const OtpSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 50),
          Image.asset(
            'assets/images/logo-taxcenter.png',
            width: 209,
            height: 81,
          ),
          SizedBox(height: 50),
          Container(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            height: 640,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), topRight: Radius.circular(50)),
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(children: [
              SizedBox(height: 103),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                    color: Color(0xff00F2C1),
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 50),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Text('Verifikasi OTP Berhasil',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 109, 109, 109),
                  ),
                  'Selamat! Verifikasi OTP akun anda berhasil. Silahkan mengisi identitas diri untuk verifikasi akun anda.',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 25),

              // VERIFIKASI BUTTON
              Container(
                width: 360,
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF080C67),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Get.toNamed(Routes.infoScreen);
                    },
                    child: Text(
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      'Selanjutnya',
                    ),
                  ),
                ),
              ),
              // END VERIFIKASI BUTTON
            ]),
          ),
        ],
      ),
    )));
  }
}
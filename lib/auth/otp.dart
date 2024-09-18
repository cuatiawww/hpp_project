import 'package:flutter/material.dart';
import 'package:hpp_project/auth/otp_success.dart';
import 'package:hpp_project/auth/otp_success.dart';
import 'package:sms_autofill/sms_autofill.dart';


class Otp extends StatefulWidget {
  const Otp({super.key});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  @override
  void initState() {
    super.initState();
    _listenOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(children: [
          SizedBox(height: 70),
          Image.asset(
            'assets/images/logo-taxcenter.png',
            width: 209,
            height: 81,
          ),
          SizedBox(height: 70),
          Container(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              height: 605,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50)),
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Text('Verifikasi OTP',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                  SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff6F6F6F),
                      ),
                      'Masukkan kode verifikasi yang dikirim ke nomor anda +62 *******10.',
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // INPUT OTP
                  SizedBox(height: 50),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: PinFieldAutoFill(
                        decoration: BoxLooseDecoration(
                          strokeColorBuilder: FixedColorBuilder(Colors.black),
                          radius: Radius.circular(8),
                        ),
                        codeLength: 6,
                        cursor: Cursor(
                          width: 1,
                          color: Colors.black,
                          enabled: true,
                        ),
                        onCodeChanged: (val) {
                          print(val);
                        },
                      ),
                    ),
                  ),
                  // END INPUT OTP

                  // VERIFIKASI BUTTON
                  SizedBox(height: 50),
                  Container(
                    width: 360,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF080C67),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        key: Key('verif'),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OtpSuccess()));

                          // if (_formKey.currentState!.validate()) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(content: Text('Processing Data')),
                          //   );
                          // }
                          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashView()));
                        },
                        child: Text(
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          'Verifikasi',
                        ),
                      ),
                    ),
                  ),
                  // END VERIFIKASI BUTTON

                  // KIRIM ULANG KODE TEKS BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          style: TextStyle(
                            color: Color(0xFF4D4B4D),
                          ),
                          'Tidak menerima kode?'),
                      TextButton(
                        style: TextButton.styleFrom(
                          textStyle: TextStyle(
                            color: Color(0xFF3E63F4),
                          ),
                        ),
                        key: Key('Login'),
                        onPressed: () {
                          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                        },
                        child: Text(
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4060F2),
                            ),
                            'Kirim ulang'),
                      ),
                    ],
                  ),
                  // END KIRIM ULANG KODE TEKS BUTTON
                ],
              )),
        ]),
      )),
    );
  }

  void _listenOtp() async {
    await SmsAutoFill().listenForCode();
  }
}
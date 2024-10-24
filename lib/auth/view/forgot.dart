import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:hpp_project/auth/reset.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class ForgotPage extends StatefulWidget {
  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final emailC = TextEditingController();

  final authC = Get.find<AuthController>();

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
                padding: EdgeInsets.symmetric(horizontal: 32),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                height: 650,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)),
                  color: Color(0xffFFFFFF),
                ),
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Text('Lupa Kata Sandi',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 24)),
                      SizedBox(height: 5),
                      Text(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        'Kami akan mengirimkan email berisi tautan untuk mengatur ulang kata sandi Anda.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 60),
                      // INPUT EMAIL
                      Row(
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      FormBuilderTextField(
                        controller: emailC,
                        validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                        key: Key('email'),
                        name: 'email',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(),
                          ),
                          hintText: 'Masukkan Email Anda*',
                        ),
                      ),
                      // END INPUT EMAIL

                      // SUBMIT BUTTON
                      SizedBox(height: 30),
                      Container(
                        width: 360,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF080C67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          key: Key('forgot'),
                          onPressed: () =>
                              authC.resetPassword(emailC.text),
                        
                          // {Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResetPage()));},
                          child: Text(
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            'Kirim Email',
                          ),
                        ),
                      ),
                      // END SUBMIT BUTTON
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

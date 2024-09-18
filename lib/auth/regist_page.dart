import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/login.dart';
import 'package:hpp_project/auth/otp.dart';
import 'package:hpp_project/user_auth/auth_controller.dart';
import 'package:sms_autofill/sms_autofill.dart';



class RegistPage extends StatelessWidget {
  final _formKey = GlobalKey<FormBuilderState>();
  
  final authC = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/images/logo-taxcenter.png',
                width: 209,
                height: 81,
              ),
              SizedBox(height: 40),
              Container(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                height: 670,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                  color: Color.fromARGB(255, 255, 255, 255),                  
                ),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Text('Buat Akun Anda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                    SizedBox(height: 40),
                    // INPUT EMAIL
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Email',
                            style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FormBuilderTextField(
                        key: Key('email'),
                        name: 'email',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                          ),
                          hintText: 'Masukkan Email Anda*',
                          ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'Email wajib diisi'),
                          FormBuilderValidators.email(),
                        ]),
                      ),
                    ),
                    // END INPUT EMAIL

                    // INPUT USERNAME
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Nama Lengkap',
                            style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FormBuilderTextField(
                        key: Key('username'),
                        name: 'username',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                          ),
                          hintText: 'Masukkan Nama Anda*',
                          ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'Username wajib diisi'),
                          FormBuilderValidators.email(),
                        ]),
                      ),
                    ),
                    // END INPUT USERNAME

                    // INPUT NOMOR TELEPON
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Nomor Telepon',
                            style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FormBuilderTextField(
                      name: 'telp',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(),
                        ),
                        hintText: 'Masukkan Nomor Telepon Anda*'
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)], // Input hanya bisa angka dengan maksimal 13 digit
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    ),
                    // END INPUT NOMOR TELEPON
                    
                    // INPUT PASSWORD
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Password',
                            style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: FormBuilderTextField(
                        key: Key('password'),
                        name: 'password',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                          ),
                          hintText: 'Masukkan Password Anda*',
                          ),
                        obscureText: true,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.password(
                            errorText: 'Password wajib diisi',
                          ),
                        ]),
                      ),
                    ),
                    // END INPUT PASSWORD

                    // SUBMIT BUTTON
                    SizedBox(height: 30),
                    Container(
                      width: 360,
                      height: 50,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF080C67),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          key: Key('ver_otp'),
                          onPressed: () async {
                            // HTTP REQUEST
                            final signcode = await SmsAutoFill().getAppSignature;
                            print(signcode);
                            // END HTTP REQUEST
                            Navigator.push(context, MaterialPageRoute(builder: (c) => Otp()));
                          },
                          child: Text(
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            'Daftar',
                          ),
                        ),
                      ),
                    ),
                    // END SUBMIT BUTTON

                    // LOGIN TEKS BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah memiliki akun?'
                        ),
                        TextButton(
                          key: Key('Login'),
                          onPressed: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                          },
                          child: Text(
                            style: TextStyle(
                              color: Color(0xFF3E63F4),
                            ),
                            'Masuk',
                            ),
                        ),
                      ],
                    ),
                    // END LOGIN TEKS BUTTON
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

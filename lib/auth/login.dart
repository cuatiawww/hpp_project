import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/regist_page.dart';
import 'package:hpp_project/auth/forgot.dart';
import 'package:hpp_project/user_auth/auth_controller.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isChecked = false; // State untuk Checkbox

  final emailC = TextEditingController(text: "testlogin@gmail.com");
  final passC = TextEditingController(text: "123123");

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
            clipBehavior: Clip.antiAliasWithSaveLayer,
            height: 640,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), topRight: Radius.circular(50)),
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(
              children: [
                SizedBox(height: 40),
                Text('Masuk Akun',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                SizedBox(height: 30),

                // INPUT USERNAME
                SizedBox(height: 15),
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
                    controller: emailC,
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
                      FormBuilderValidators.required(
                          errorText: 'Email wajib diisi'),
                      FormBuilderValidators.email(),
                    ]),
                  ),
                ),
                // END INPUT USERNAME

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
                    controller: passC,
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

                Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked = value ?? false;
                                });
                              },
                              activeColor: Color(0xFF080C67),
                            ),
                            Text('Ingat Saya'),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ForgotPage()));
                              },
                              child: Text(
                                'Lupa Password?',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SUBMIT BUTTON
                  SizedBox(height: 30),
                  Container(
                    width: 360,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF080C67),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        key: Key('Login'),
                        onPressed: () => authC.login(emailC.text, passC.text),
                        child: Text(
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          'Masuk',
                        ),
                      ),
                    ),
                  ),
                  // END SUBMIT BUTTON

                  // LOGIN TEKS BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum memiliki akun?'),
                      TextButton(
                        style: TextButton.styleFrom(
                          textStyle: TextStyle(
                            color: Color(0xFF3E63F4),
                          ),
                        ),
                        key: Key('Regist'),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegistPage()));
                        },
                        child: Text(
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            'Daftar'),
                      ),
                    ],
                  ),
                  // END LOGIN TEKS BUTTON
                ]),
              ],
            ),
          ),
        ],
      ),
    )));
  }
}
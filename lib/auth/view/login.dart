import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/view/regist_page.dart';
import 'package:hpp_project/auth/view/forgot.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/home_page.dart';
import 'package:hpp_project/routes/routes.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formState = GlobalKey<FormState>(); // Key untuk validasi form

  bool isChecked = false; // State untuk Checkbox

  // Email dan Password Controller
  final TextEditingController emailController = TextEditingController(); //text: "testlogin@gmail.com"
  final TextEditingController passController = TextEditingController(); //text: "123123"

  // Obsecure Password
  var _isObscured;

  // Set Obsecure Password
  @override
  void initState() {
    super.initState();
    _isObscured = true;
  }

  // Login Function
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50), //BISA DI WRAP DENGAN PADDING BIAR LEBIH RAPIH
            Image.asset(
              'assets/images/logo-taxcenter.png',
              width: 209,
              height: 81,
            ),
            SizedBox(height: 50),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              height: 640,
              // width: MediaQuery.of(context).size.width,
              // height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50)),
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: Form(
                key: _formState,
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Text('Masuk Akun',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        )),
                    SizedBox(height: 30),

                    // INPUT USERNAME
                    SizedBox(height: 15),
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
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                        ),
                        hintText: 'Masukkan Email Anda',
                      ),
                    ),
                    // END INPUT USERNAME

                    // INPUT PASSWORD
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    TextFormField(
                      obscureText: _isObscured,
                      controller: passController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        return null;
                      },
                      key: Key('password'),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: _isObscured
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                        ),
                        hintText: 'Masukkan Password Anda',
                      ),
                    ),
                    // END INPUT PASSWORD

                    Column(children: [
                      Row(
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
                                onPressed: () => Get.toNamed(Routes.forgot),
                                child: Text(
                                  'Lupa Password?',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

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
                          onPressed: () {
                            if (_formState.currentState!.validate()) {
                              // Jika valid, panggil fungsi untuk login
                              authController.login(emailController.text, passController.text);
                            } else {
                              // Jika tidak valid, tampilkan pesan error
                              print("Form tidak valid");
                            }
                          },
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
                            onPressed: () => Get.toNamed(Routes.regist),
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
            ),
          ],
        ),
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class RegistPage extends StatefulWidget {
  const RegistPage({Key? key}) : super(key: key);

  @override
  State<RegistPage> createState() => _RegistPageState();
}

class _RegistPageState extends State<RegistPage> {
  final _formState = GlobalKey<FormState>(); // Key untuk validasi form

  // Email dan Password Controller
  final emailController = TextEditingController(); //text: "testlogin@gmail.com"
  final passController = TextEditingController(); //text: "123123"

  // Obsecure Password
  var _isObscured;  

  // Set Obsecure Password
  @override
  void initState() {
    super.initState();
    _isObscured = true;
  }

  final authController = Get.find<AuthController>();

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
                padding: EdgeInsets.symmetric(horizontal: 32),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                height: 670,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                  color: Color.fromARGB(255, 255, 255, 255),                  
                ),
                child: Form(
                  key: _formState,
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Text('Buat Akun Anda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                      SizedBox(height: 40),
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
                          hintText: 'Masukkan Email Anda*',
                          ),
                        
                      ),
                      // END INPUT EMAIL
                  
                      // INPUT USERNAME
                      // SizedBox(height: 15),
                      // Row(
                      //   children: [
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 32),
                      //       child: Text(
                      //         'Nama Lengkap',
                      //         style: TextStyle(
                      //         fontWeight: FontWeight.w600, 
                      //         fontSize: 14,
                      //         ),
                      //         textAlign: TextAlign.start,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // SizedBox(height: 5),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 32),
                      //   child: FormBuilderTextField(
                      //     key: Key('username'),
                      //     name: 'username',
                      //     decoration: InputDecoration(
                      //       border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8),
                      //       borderSide: BorderSide(),
                      //       ),
                      //       hintText: 'Masukkan Nama Anda*',
                      //       ),
                      //     validator: FormBuilderValidators.compose([
                      //       FormBuilderValidators.required(errorText: 'Username wajib diisi'),
                      //       FormBuilderValidators.email(),
                      //     ]),
                      //   ),
                      // ),
                      // END INPUT USERNAME
                  
                      // INPUT NOMOR TELEPON
                      // SizedBox(height: 15),
                      // Row(
                      //   children: [
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 32),
                      //       child: Text(
                      //         'Nomor Telepon',
                      //         style: TextStyle(
                      //         fontWeight: FontWeight.w600, 
                      //         fontSize: 14,
                      //         ),
                      //         textAlign: TextAlign.start,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // SizedBox(height: 5),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 32),
                      //   child: FormBuilderTextField(
                      //   name: 'telp',
                      //   decoration: InputDecoration(
                      //     border: OutlineInputBorder(
                      //     borderRadius: BorderRadius.circular(8),
                      //     borderSide: BorderSide(),
                      //     ),
                      //     hintText: 'Masukkan Nomor Telepon Anda*'
                      //     ),
                      //     keyboardType: TextInputType.number,
                      //     inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)], // Input hanya bisa angka dengan maksimal 13 digit
                      //   validator: FormBuilderValidators.compose([
                      //     FormBuilderValidators.required(),
                      //   ]),
                      // ),
                      // ),
                      // END INPUT NOMOR TELEPON
                      
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
                            icon: _isObscured ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
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
                          hintText: 'Masukkan Password Anda*',
                          ),
                      ),
                      // END INPUT PASSWORD
                  
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
                                // Jika valid, panggil fungsi untuk Regist
                                authController.signup(
                                  emailController.text.trim(), 
                                  passController.text.trim()
                                );
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
                            'Daftar',
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
                            onPressed: () => Get.toNamed('/login'),
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
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

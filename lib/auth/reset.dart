import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hpp_project/auth/login.dart';


class ResetPage extends StatelessWidget {
  const ResetPage({super.key});

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
                height: 550,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                  color: Color(0xffFFFFFF),                  
                ),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Text('Atur Ulang Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        'Yuk, kita atur ulang kata sandi Anda agar akun Anda tetap aman!',
                        textAlign: TextAlign.center,
                        ),
                    ),
                    SizedBox(height: 60),
                    // INPUT RESET PASSWORD
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Kata Sandi Baru',
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
                        key: Key('new_password'),
                        name: 'new_password',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                          ),
                          hintText: 'Masukkan Kata Sandi Baru*',
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
                    // END INPUT RESET PASSWORD

                    // INPUT RESET PASSWORD
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Konfirmasi Kata Sandi Baru',
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
                          hintText: 'Konfirmasi Kata Sandi*',
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
                    // END INPUT RESET PASSWORD

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
                          key: Key('forgot'),
                          onPressed: () {
                            // if (_formKey.currentState!.validate()) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(content: Text('Processing Data')),
                            //   );
                            // }
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                          },
                          child: Text(
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            'Atur Ulang',
                          ),
                        ),
                      ),
                    ),
                    // END SUBMIT BUTTON

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
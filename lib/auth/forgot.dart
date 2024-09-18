import 'package:flutter/material.dart';
import 'package:hpp_project/auth/reset.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ForgotPage extends StatelessWidget {
  const ForgotPage({super.key});

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
                    Text('Lupa Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        'Kami akan mengirimkan email berisi tautan untuk mengatur ulang kata sandi Anda.',
                        textAlign: TextAlign.center,
                        ),
                    ),
                    SizedBox(height: 60),
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
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResetPage()));
                          },
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
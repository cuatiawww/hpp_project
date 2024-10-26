import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/view/info_screen.dart';

import 'package:hpp_project/Perusahaan%20Dagang/pages/home_page.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/input_pers_awal.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_awal.dart';
import 'package:hpp_project/Onboarding/onboarding_view.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_calculation_page.dart';

import 'package:hpp_project/routes/routes.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';
import 'package:hpp_project/utils/loading.dart';

import 'package:hpp_project/auth/view/login.dart';
import 'package:hpp_project/auth/view/forgot.dart';
import 'package:hpp_project/auth/view/otp.dart';
import 'package:hpp_project/auth/view/reset.dart';
import 'package:hpp_project/auth/view/regist_page.dart';
import 'package:hpp_project/auth/view/otp_success.dart';
// import 'dart:io';

// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final authC = Get.put(AuthController(), permanent: true);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authC.streamAuthStatus,
      builder: (context, snapshot){
        print(snapshot.data);
        if(snapshot.connectionState == ConnectionState.active){
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'HPP Tax Center',
            theme: ThemeData(
              fontFamily: 'Poppins',
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            initialRoute: snapshot.data != null ? Routes.home : Routes.onboarding,
            getPages: [
              GetPage(name: Routes.onboarding, page: () => OnboardingView()),
              GetPage(name: Routes.login, page: () => LoginPage()),
              GetPage(name: Routes.regist, page: () => RegistPage()),
              GetPage(name: Routes.forgot, page: () => ForgotPage()),
              GetPage(name: Routes.otp, page: () => Otp()),
              GetPage(name: Routes.otpSuccess, page: () => OtpSuccess()),
              GetPage(name: Routes.reset, page: () => ResetPage()),
              GetPage(name: Routes.home, page: () => HomePage()),
              GetPage(name: Routes.inputPersAwal, page: () => InputPersAwal()),
              GetPage(name: Routes.persAwal, page: () => PersAwal()),
              GetPage(name: Routes.persAkhir, page: () => PersAkhirPage()),
              GetPage(name: Routes.infoScreen, page: () => InfoScreen(uid: Get.arguments as String)),
            ],
            // home: snapshot.data != null ? HomePage====() : onboardingView(),
          );
        }
        return LoadingView();
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hpp_project/pages/home_page.dart';
import 'package:hpp_project/pages/input_pers_awal.dart';
import 'package:hpp_project/pages/pers_awal.dart';
import 'package:hpp_project/pages/splash_view.dart';
import 'package:hpp_project/pages/hpp_calculation_page.dart';

import 'package:hpp_project/routes/routes.dart';
import 'package:hpp_project/user_auth/auth_controller.dart';
import 'package:hpp_project/utils/loading.dart';

import 'package:hpp_project/auth/login.dart';
import 'package:hpp_project/auth/forgot.dart';
import 'package:hpp_project/auth/otp.dart';
import 'package:hpp_project/auth/reset.dart';
import 'package:hpp_project/auth/regist_page.dart';
import 'package:hpp_project/auth/otp_success.dart';
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
            initialRoute: snapshot.data != null ? Routes.home : Routes.splash,
            getPages: [
              GetPage(name: Routes.splash, page: () => SplashView()),
              GetPage(name: Routes.login, page: () => LoginPage()),
              GetPage(name: Routes.regist, page: () => RegistPage()),
              GetPage(name: Routes.forgot, page: () => ForgotPage()),
              GetPage(name: Routes.otp, page: () => Otp()),
              GetPage(name: Routes.otpSuccess, page: () => OtpSuccess()),
              GetPage(name: Routes.reset, page: () => ResetPage()),
              GetPage(name: Routes.home, page: () => HomePage()),
              GetPage(name: Routes.inputPersAwal, page: () => InputPersAwal()),
              GetPage(name: Routes.persAwal, page: () => PersAwal()),
            ],
            // home: snapshot.data != null ? HomePage() : SplashView(),
          );
        }
        return LoadingView();
      },
    );
  }
}

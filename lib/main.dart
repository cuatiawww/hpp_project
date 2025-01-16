import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/view/verify_email.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hpp_project/Perusahaan_Dagang/notification/notif.dart';
import 'package:hpp_project/Splash_Screen/splash_screen.dart';
import 'package:hpp_project/auth/view/info_screen.dart';
import 'package:hpp_project/home/home_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/input_pers_awal.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_awal_page.dart';
import 'package:hpp_project/onboarding/onboarding_view.dart';

import 'package:hpp_project/routes/routes.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

import 'package:hpp_project/auth/view/login.dart';
import 'package:hpp_project/auth/view/forgot.dart';
import 'package:hpp_project/auth/view/reset.dart';
import 'package:hpp_project/auth/view/regist_page.dart';
import 'package:hpp_project/auth/view/otp_success.dart';
// Import file TestFirestoreConnection
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

  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstTime') ?? true; // Default true jika belum ada data.
  }

  void setFirstTimeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // Tandai bahwa onboarding selesai.
  }
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HPP Tax Center',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Selalu tampilkan splash screen sebagai halaman pertama.
      home: SplashScreen(
        onComplete: () async {
          final isFirstTime = await this.isFirstTime();
          final currentUser = FirebaseAuth.instance.currentUser;
            
            if (isFirstTime) {
              // setFirstTimeCompleted(); // Tandai onboarding selesai.
              Get.offAllNamed(Routes.onboarding); // Arahkan ke Onboarding.
            } else if (currentUser != null) {
              Get.offAllNamed(Routes.home); // Jika sudah login, arahkan ke Home.
            } else {
              Get.offAllNamed(Routes.login); // Jika belum login, arahkan ke Login.
            }
          },
        ),
        getPages: [
          GetPage(name: Routes.onboarding, page: () => OnboardingView()),
          GetPage(name: Routes.login, page: () => LoginPage()),
          GetPage(name: Routes.regist, page: () => RegistPage()),
          GetPage(name: Routes.forgot, page: () => ForgotPage()),
          // GetPage(name: Routes.otp, page: () => Otp()),
          GetPage(name: Routes.otpSuccess, page: () => OtpSuccess()),
          GetPage(name: Routes.reset, page: () => ResetPage()),
          GetPage(name: Routes.home, page: () => HomePage()),
          GetPage(name: Routes.inputPersAwal, page: () => InputPersAwal()),
          GetPage(name: Routes.persAwal, page: () => PersAwal()),
          GetPage(name: Routes.persAkhir, page: () => PersAkhirPage()),
          GetPage(name: Routes.infoScreen, page: () => InfoScreen()),
          GetPage(name: Routes.notif, page: () => NotificationPage()),
          GetPage(name: Routes.verifyEmail, page: () => VerifyEmailPage()),
          GetPage(
            name: Routes.splashScreen, 
            page: () => SplashScreen(
              onComplete: () {}
          )
        ),
      ],
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hpp_project/routes/routes.dart';
import 'package:hpp_project/routes/routes.dart';

class AuthController extends GetxController{
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> get streamAuthStatus => auth.authStateChanges();
  
  void login (String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
      );
      Get.offAllNamed(Routes.home);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }
  void signup () {} 
  void logout () async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.login);
  }
  
}
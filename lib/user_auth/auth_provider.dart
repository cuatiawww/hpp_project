// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';


// final _fireAuth = FirebaseAuth.instance;
// class AuthProvider extends ChangeNotifier {
//   final form = GlobalKey<FormState>();

//   var islogin = true;
//   var enteredEmail = '';
//   var enteredPassword = '';
//   var enteredUsername = '';
//   var enteredPhoneNumber = '';

//   void submit() async {
//     final isValid = form.currentState!.validate();

//     if(!isValid) {
//       return;
//     }

//     form.currentState!.save();

//     try {
//       if(islogin) {
//         final UserCredential = await _fireAuth.signInWithEmailAndPassword(email: enteredEmail, password: enteredPassword);
//       }else{
//         final UserCredential = await _fireAuth.createUserWithEmailAndPassword(email: enteredEmail, password: enteredPassword);
//       }
//     } catch(e) {
//       if(e is FirebaseAuthException){
//         if(e.code == 'email-already-in-use' ) {
//           print('email sudah digunakan');
//         }
//       }
//     }

//     notifyListeners();
//   }
// }
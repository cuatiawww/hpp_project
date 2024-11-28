// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// import 'package:hpp_project/auth/controllers/auth_controller.dart';

// class Otp extends StatefulWidget {
//   const Otp({super.key});

//   @override
//   State<Otp> createState() => _OtpState();
// }

// class _OtpState extends State<Otp> {
//   final TextEditingController _otpController = TextEditingController();
//   final AuthController _authController = Get.find<AuthController>();
//   bool _isLoading = false;
//   final int _otpLength = 6;

//   @override
//   void initState() {
//     super.initState();
//     _listenOtp();
//     _checkEmailAvailability();
//   }

//   void _checkEmailAvailability() {
//     if (_authController.tempEmail == null) {
//       // Jika tidak ada email, kembali ke halaman sebelumnya
//       Get.back();
//       _showSnackbar(
//         'Sesi pendaftaran tidak valid. Silakan daftar ulang.',
//         isError: true,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _otpController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleOtpVerification() async {
//     if (_otpController.text.length != _otpLength) {
//       _showSnackbar(
//         'Masukkan kode OTP yang valid',
//         isError: true,
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//     await _authController.verifyOTP(_otpController.text); // Tunggu hasil verifikasi OTP
//     await _authController.finalizeRegistration(); // Jika berhasil, lanjutkan proses registrasi
//   } catch (e) {
//     _showSnackbar(
//       'Kode OTP tidak valid atau terjadi kesalahan. Silakan coba lagi.',
//       isError: true,
//     );
//   } finally {
//     setState(() => _isLoading = false);
//   }
// }

//   Future<void> _resendOtp() async {
//     if (_isLoading) return;

//     final email = _authController.tempEmail;
//     if (email == null) {
//       _showSnackbar(
//         'Email tidak tersedia. Silakan daftar ulang.',
//         isError: true,
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
    
//     try {
//       await _authController.sendOTP(email);
//       _showSnackbar('Kode OTP baru telah dikirim');
//     } catch (e) {
//       _showSnackbar(
//         'Gagal mengirim kode OTP',
//         isError: true,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showSnackbar(String message, {bool isError = false}) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: isError ? Colors.redAccent : Colors.greenAccent[400],
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   void _listenOtp() async {
//     await SmsAutoFill().listenForCode();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         // Mencegah kembali ke halaman sebelumnya saat proses loading
//         return !_isLoading;
//       },
//     child: Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 70),
//               Image.asset(
//                 'assets/images/logo-taxcenter.png',
//                 width: 209,
//                 height: 81,
//               ),
//               const SizedBox(height: 70),
//               Container(
//                 clipBehavior: Clip.antiAliasWithSaveLayer,
//                 height: 605,
//                 decoration: const BoxDecoration(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(50),
//                     topRight: Radius.circular(50),
//                   ),
//                   color: Colors.white,
//                 ),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 50),
//                     const Text(
//                       'Verifikasi OTP',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 24,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 30),
//                       child: Text(
//                         'Masukkan kode verifikasi yang dikirim ke ${_authController.tempEmail ?? "email anda"}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xff6F6F6F),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(height: 50),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 30),
//                       child: PinCodeTextField(
//                         appContext: context,
//                         length: _otpLength,
//                         controller: _otpController,
//                         onChanged: (value) {},
//                         pinTheme: PinTheme(
//                           shape: PinCodeFieldShape.box,
//                           borderRadius: BorderRadius.circular(8),
//                           fieldHeight: 50,
//                           fieldWidth: 45,
//                           activeFillColor: Colors.white,
//                           inactiveFillColor: Colors.white,
//                           selectedFillColor: Colors.white,
//                           activeColor: const Color(0xFF080C67),
//                           inactiveColor: Colors.grey,
//                           selectedColor: const Color(0xFF080C67),
//                         ),
//                         keyboardType: TextInputType.number,
//                         enableActiveFill: true,
//                       ),
//                     ),
//                     const SizedBox(height: 50),
//                     SizedBox(
//                       width: 360,
//                       height: 50,
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 14),
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF080C67),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                           ),
//                           onPressed: _isLoading ? null : _handleOtpVerification,
//                           child: _isLoading
//                               ? const CircularProgressIndicator(color: Colors.white)
//                               : const Text(
//                                   'Verifikasi',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           'Tidak menerima kode?',
//                           style: TextStyle(
//                             color: Color(0xFF4D4B4D),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: _isLoading ? null : _resendOtp,
//                           child: const Text(
//                             'Kirim ulang',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               color: Color(0xFF4060F2),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//     );
//   }
// }
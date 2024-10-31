import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DataPribadiController extends GetxController {
  final String uid;
  DataPribadiController({required this.uid});
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables untuk menyimpan data pengguna
  var namaLengkap = ''.obs;
  var npwp = ''.obs;
  var tanggalLahir = ''.obs;
  var jenisKelamin = ''.obs;

  // Fetch user data
  Future<void> fetchDataPribadi() async {
    // Ambil UID pengguna (misalkan Anda memiliki cara untuk mendapatkan UID)
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot = await _firestore
      .collection('Users')
      .doc(uid)
      .collection('PersonalData')
      .doc('dataPribadi')
      .get();
      if (snapshot.exists) {
        namaLengkap.value = snapshot['namaLengkap'] ?? '';
        npwp.value = snapshot['npwp'] ?? '';
        tanggalLahir.value = snapshot['tanggalLahir'] ?? '';
        jenisKelamin.value = snapshot['jenisKelamin'] ?? '';
      } 
    } else {
      print('Pengguna belum login');
    }
  }

  // Add user data
  Future<void> addDataPribadi(String newNamaLengkap, String newNpwp, String newTanggalLahir, String newJenisKelamin) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection('Users').doc(uid).collection('PersonalData').doc('dataPribadi').set({
      'Nama Lengkap': newNamaLengkap,
      'NPWP': newNpwp,
      'Tanggal Lahir': newTanggalLahir,
      'Jenis Kelamin': newJenisKelamin,
    });
    fetchDataPribadi(); // Fetch updated data
  }

  // Update user data
  Future<void> updateDataPribadi(String newNamaLengkap, String newNpwp, String newTanggalLahir, String newJenisKelamin) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection('Users').doc(uid).collection('PersonalData').doc('dataPribadi').update({
      'namaLengkap': newNamaLengkap,
      'npwp': newNpwp,
      'tanggalLahir': newTanggalLahir,
      'jenisKelamin': newJenisKelamin,
    });
    fetchDataPribadi(); // Fetch updated data
  }
}
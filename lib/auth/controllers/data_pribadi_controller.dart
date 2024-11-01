import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DataPribadiController extends GetxController {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DataPribadiController({required this.uid});

  // Observables untuk menyimpan data pengguna
  var namaLengkap = ''.obs;
  var npwp = ''.obs;
  var tanggalLahir = ''.obs;
  var jenisKelamin = ''.obs;

  // Fetch user data
  Future<void> fetchDataPribadi(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(uid)
          .collection('PersonalData')
          .doc('dataPribadi')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        namaLengkap.value = data['Nama Lengkap'] ?? '';
        npwp.value = data['NPWP'] ?? '';
        tanggalLahir.value = data['Tanggal Lahir'] ?? '';
        jenisKelamin.value = data['Jenis Kelamin'] ?? '';
      }
    } catch (e) {
      print('Error fetching personal data: $e');
    }
  }

  // Add user data
  Future<void> addDataPribadi(String newNamaLengkap, String newNpwp, String newTanggalLahir, String newJenisKelamin) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _firestore
          .collection('Users')
          .doc(uid)
          .collection('PersonalData')
          .doc('dataPribadi')
          .set({
        'Nama Lengkap': newNamaLengkap,
        'NPWP': newNpwp,
        'Tanggal Lahir': newTanggalLahir,
        'Jenis Kelamin': newJenisKelamin,
      });
      await fetchDataPribadi(uid);
    } catch (e) {
      print('Error adding personal data: $e');
    }
  }

  // Update user data
  Future<void> updateDataPribadi(String newNamaLengkap, String newNpwp, String newTanggalLahir, String newJenisKelamin) async {
    try {
      await _firestore
          .collection('Users')
          .doc(uid)
          .collection('PersonalData')
          .doc('dataPribadi')
          .update({
        'Nama Lengkap': newNamaLengkap,
        'NPWP': newNpwp,
        'Tanggal Lahir': newTanggalLahir,
        'Jenis Kelamin': newJenisKelamin,
      });
      await fetchDataPribadi(uid);
    } catch (e) {
      print('Error updating personal data: $e');
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DataUsahaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables untuk menyimpan data bisnis
  var namaUsaha = ''.obs;
  var tipeUsaha = ''.obs;
  var nomorTelepon = ''.obs;

  // Fetch business data
  Future<void> fetchnamaUsaha() async {
    // Ambil UID pengguna (misalkan Anda memiliki cara untuk mendapatkan UID)
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot = await _firestore
      .collection('Users')
      .doc(uid)
      .collection('BusinessData')
      .doc('namaUsaha')
      .get();
      if (snapshot.exists) {
        namaUsaha.value = snapshot['namaUsaha'] ?? '';
        tipeUsaha.value = snapshot['tipeUsaha'] ?? '';
        nomorTelepon.value = snapshot['nomorTelepon'] ?? '';
      } else {
        print('Pengguna belum login');
      }
    }
  }

  // Add business data
  Future<void> addnamaUsaha(String newNamaUsaha, String newTipeUsaha, String newNomorTelepon) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection('Users').doc(uid).collection('BusinessData').doc('dataUsaha').set({
      'namaUsaha': newNamaUsaha,
      'tipeUsaha': newTipeUsaha,
      'nomorTelepon': newNomorTelepon,
      'createdAt': FieldValue.serverTimestamp(),
    });
    fetchnamaUsaha(); // Fetch updated data
  }

  // Update business data
  Future<void> updatenamaUsaha(String newNamaUsaha, String newTipeUsaha, String newNomorTelepon) async {
    String uid = _auth.currentUser!.uid;
    await _firestore.collection('Users').doc(uid).collection('BusinessData').doc('dataUsaha').update({
      'namaUsaha': newNamaUsaha,
      'tipeUsaha': newTipeUsaha,
      'nomorTelepon': newNomorTelepon,
    });
    fetchnamaUsaha(); // Fetch updated data
  }
}
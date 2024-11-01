import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DataUsahaController extends GetxController {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DataUsahaController({required this.uid});

  // Observables untuk menyimpan data usaha
  var namaUsaha = ''.obs;
  var tipeUsaha = ''.obs;
  var nomorTelepon = ''.obs;

  // Fetch data usaha
  Future<void> fetchDataUsaha(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(uid)
          .collection('BusinessData')
          .doc('dataUsaha')
          .get();
          
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        namaUsaha.value = data['Nama Usaha'] ?? '';
        tipeUsaha.value = data['Tipe Usaha'] ?? '';
        nomorTelepon.value = data['Nomor Telepon'] ?? '';
      }
    } catch (e) {
      print('Error fetching business data: $e');
    }
  }

  // Add data usaha
  Future<void> addDataUsaha(String newNamaUsaha, String newTipeUsaha, String newNomorTelepon) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _firestore
          .collection('Users')
          .doc(uid)
          .collection('BusinessData')
          .doc('dataUsaha')
          .set({
        'Nama Usaha': newNamaUsaha,
        'Tipe Usaha': newTipeUsaha,
        'Nomor Telepon': newNomorTelepon,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchDataUsaha(uid);
    } catch (e) {
      print('Error adding business data: $e');
    }
  }

  // Update data usaha
  Future<void> updateDataUsaha(String newNamaUsaha, String newTipeUsaha, String newNomorTelepon) async {
    try {
      await _firestore
          .collection('Users')
          .doc(uid)
          .collection('BusinessData')
          .doc('dataUsaha')
          .update({
        'Nama Usaha': newNamaUsaha,
        'Tipe Usaha': newTipeUsaha,
        'Nomor Telepon': newNomorTelepon,
      });
      await fetchDataUsaha(uid);
    } catch (e) {
      print('Error updating business data: $e');
    }
  }
}

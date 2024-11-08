import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addNotification({
  required String title,
  required String message,
}) async {
  // Mendapatkan UID dari pengguna yang saat ini login
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid != null) {
    // Menambahkan notifikasi ke subkoleksi Notifications dari pengguna
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('Notifications')
        .add({
      'title': title,
      'message': message,
      'createdAt': Timestamp.now(),
      'isRead': false, // Untuk status notifikasi
    });
  }
}

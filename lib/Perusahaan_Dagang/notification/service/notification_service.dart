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

// Fungsi khusus untuk notifikasi pembelian
Future<void> addPembelianNotification({
  required String namaBarang,
  required int jumlah,
  required String satuan,
  required String type,
}) async {
  await addNotification(
    title: 'Pembelian Baru',
    message: 'Menambahkan pembelian $namaBarang sebanyak $jumlah $satuan dengan tipe $type',
  );
}

// Fungsi khusus untuk notifikasi penjualan
Future<void> addPenjualanNotification({
  required String namaBarang,
  required int jumlah,
  required String satuan,
  required String tipe,
}) async {
  await addNotification(
    title: 'Penjualan Baru',
    message: 'Menambahkan penjualan $namaBarang sebanyak $jumlah $satuan dengan tipe $tipe',
  );
}

// Fungsi khusus untuk notifikasi persediaan awal
Future<void> addPersediaanAwalNotification({
  required String namaBarang,
  required int jumlah,
  required String satuan,
  required String action,
}) async {
  String title;
  String message;
  
  switch (action) {
    case 'update':
      title = 'Update Persediaan Awal';
      message = 'Mengubah data $namaBarang dengan jumlah $jumlah $satuan';
      break;
    case 'delete':
      title = 'Hapus Persediaan Awal';
      message = 'Menghapus barang $namaBarang dari persediaan awal';
      break;
    default:
      title = 'Persediaan Awal Baru';
      message = 'Menambahkan $namaBarang sebanyak $jumlah $satuan ke persediaan awal';
  }
  
  await addNotification(
    title: title,
    message: message,
  );
}

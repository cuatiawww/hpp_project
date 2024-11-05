import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseMethods {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Modifikasi method addBarang
  Future<void> addBarang(Map<String, dynamic> barangInfoMap, String id) async {
    String userId = currentUserId;
    
    // Tambahkan userId dan timestamp
    final barangData = {
      ...barangInfoMap,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Simpan ke collection Barang dengan userId
    await _db.collection("Users")
        .doc(userId)
        .collection("Barang")
        .doc(id)
        .set(barangData);
    
    // Update PersediaanTotal dengan userId
    await _db.collection("Users")
        .doc(userId)
        .collection("PersediaanTotal")
        .doc(id)
        .set({
      'Name': barangData['Name'],
      'Tipe': barangData['Tipe'],
      'Jumlah': barangData['Jumlah'],
      'Price': barangData['Price'],
      'Satuan': barangData['Satuan'],
      'Tanggal': barangData['Tanggal'],
      'LastUpdated': FieldValue.serverTimestamp(),
    });

    // Add to Riwayat dengan userId
    await _db.collection("Users")
        .doc(userId)
        .collection("Riwayat")
        .add({
      'type': 'Persediaan Awal',
      'name': barangData['Name'],
      'tipe': barangData['Tipe'],
      'jumlah': barangData['Jumlah'],
      'price': barangData['Price'],
      'satuan': barangData['Satuan'],
      'tanggal': barangData['Tanggal'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Modifikasi method untuk mendapatkan barang
  Stream<QuerySnapshot> getBarangDetails() {
    String userId = currentUserId;
    return _db.collection("Users")
        .doc(userId)
        .collection("Barang")
        .snapshots();
  }

  // Modifikasi method addPembelian
  Future<void> addPembelian(Map<String, dynamic> pembelianData) async {
    String userId = currentUserId;
    
    // Tambahkan userId dan timestamp
    pembelianData['userId'] = userId;
    pembelianData['createdAt'] = FieldValue.serverTimestamp();

    // Simpan ke collection Pembelian
    DocumentReference pembelianRef = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .add(pembelianData);

    // Add to Riwayat
    await _db.collection("Users")
        .doc(userId)
        .collection("Riwayat")
        .add({
      'type': 'Pembelian',
      'name': pembelianData['Name'],
      'tipe': pembelianData['Type'],
      'jumlah': pembelianData['Jumlah'],
      'price': pembelianData['Price'],
      'satuan': pembelianData['Satuan'],
      'tanggal': pembelianData['Tanggal'],
      'timestamp': FieldValue.serverTimestamp(),
    });

//     Stream<QuerySnapshot> getPenjualanDetails() {
//     String userId = currentUserId;
//     return _db.collection("Users")
//         .doc(userId)
//         .collection("Penjualan")
//         .snapshots();
//   }
//  Stream<QuerySnapshot> getPenjualanStream() {
//   String userId = currentUserId;
//   print("Current User ID: $userId"); // Untuk debugging
  
//   return _db
//       .collection("Users")
//       .doc(userId)
//       .collection("Penjualan")
//       .orderBy('timestamp', descending: true)
//       .snapshots();
// }

//   Future<void> addPenjualan(Map<String, dynamic> penjualanData) async {
//     String userId = currentUserId;
//     await _db.collection("Users")
//         .doc(userId)
//         .collection("Penjualan")
//         .add(penjualanData);
//         // Update stok barang
//     await updateStokAfterPenjualan(
//       penjualanData['barangId'],
//       penjualanData['jumlah']
//     );
//   }
  

    // Update PersediaanTotal
    try {
      final QuerySnapshot totalSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("PersediaanTotal")
          .where('Name', isEqualTo: pembelianData['Name'])
          .where('Tipe', isEqualTo: pembelianData['Type'])
          .get();

      if (totalSnapshot.docs.isNotEmpty) {
        await _db
            .collection("Users")
            .doc(userId)
            .collection("PersediaanTotal")
            .doc(totalSnapshot.docs.first.id)
            .update({
          'Jumlah': FieldValue.increment(pembelianData['Jumlah'] as int),
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await _db
            .collection("Users")
            .doc(userId)
            .collection("PersediaanTotal")
            .add({
          'Name': pembelianData['Name'],
          'Tipe': pembelianData['Type'],
          'Jumlah': pembelianData['Jumlah'],
          'Price': pembelianData['Price'],
          'Satuan': pembelianData['Satuan'],
          'Tanggal': pembelianData['Tanggal'],
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      await pembelianRef.delete();
      throw Exception('Failed to update total persediaan: $e');
    }
  }



  // Modifikasi method untuk mendapatkan pembelian


  Stream<QuerySnapshot> getPersediaanTotal() {
    String userId = currentUserId;
    return _db.collection("Users")
        .doc(userId)
        .collection("PersediaanTotal")
        .snapshots();
  }
Stream<QuerySnapshot<Map<String, dynamic>>> getLaporanPenjualanStream(
      String startDate, String endDate) {
    String userId = currentUserId;
    return _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('tanggal', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLaporanPembelianStream(
      String startDate, String endDate) {
    String userId = currentUserId;
    return _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('Tanggal', descending: true)
        .snapshots();
  }
// PENJUALAN METHODS
 Stream<QuerySnapshot<Map<String, dynamic>>> getPenjualanStream() {
    String userId = currentUserId;
    return _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .orderBy('tanggal')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPembelianDetails() {
    String userId = currentUserId;
    return _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .orderBy('Tanggal')
        .snapshots();
  }
  
  Future<void> addPenjualan(Map<String, dynamic> penjualanData) async {
    String userId = currentUserId;
    print("Adding penjualan for userId: $userId"); // Debug print
    
    try {
      // Simpan ke collection Penjualan
      DocumentReference penjualanRef = await _db
          .collection("Users")
          .doc(userId)
          .collection("Penjualan")
          .add({
        ...penjualanData,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Penjualan saved with ID: ${penjualanRef.id}"); // Debug print

      // Update stok barang
      await updateStokAfterPenjualan(
        penjualanData['barangId'], 
        penjualanData['jumlah']
      );

      // Add to Riwayat
      await _db
          .collection("Users")
          .doc(userId)
          .collection("Riwayat")
          .add({
        'type': 'Penjualan',
        'namaBarang': penjualanData['namaBarang'],
        'tipe': penjualanData['tipe'],
        'jumlah': penjualanData['jumlah'],
        'hargaJual': penjualanData['hargaJual'],
        'total': penjualanData['total'],
        'satuan': penjualanData['satuan'],
        'tanggal': penjualanData['tanggal'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error in addPenjualan: $e"); // Debug print
      throw e;
    }
  }


  //PENJUALAN
  
  Future<void> updateStokAfterPenjualan(String barangId, int jumlahTerjual) async {
    String userId = currentUserId;
    final barangRef = _db
        .collection("Users")
        .doc(userId)
        .collection("Barang")
        .doc(barangId);
    
    await _db.runTransaction((transaction) async {
      final barangDoc = await transaction.get(barangRef);
      if (!barangDoc.exists) {
        throw Exception("Barang tidak ditemukan");
      }
      
      final currentStock = barangDoc.data()!['Jumlah'] as int;
      if (currentStock < jumlahTerjual) {
        throw Exception("Stok tidak mencukupi");
      }
      
      transaction.update(barangRef, {
        'Jumlah': currentStock - jumlahTerjual
      });

      // Update PersediaanTotal juga
      final persediaanRef = _db
          .collection("Users")
          .doc(userId)
          .collection("PersediaanTotal")
          .doc(barangId);

      final persediaanDoc = await transaction.get(persediaanRef);
      if (persediaanDoc.exists) {
        transaction.update(persediaanRef, {
          'Jumlah': FieldValue.increment(-jumlahTerjual),
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  // Modifikasi method update dan delete
  Future<void> updateBarangDetail(String id, Map<String, dynamic> updateInfo) async {
    String userId = currentUserId;
    try {
      await _db.collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(id)
          .update(updateInfo);
      
      await _db.collection("Users")
          .doc(userId)
          .collection("PersediaanTotal")
          .doc(id)
          .update({
        ...updateInfo,
        'LastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating document: $e");
      throw e;
    }
  }

  Future<void> deleteBarangDetail(String id) async {
    String userId = currentUserId;
    WriteBatch batch = _db.batch();
    
    try {
      // Delete from Barang
      batch.delete(_db.collection("Users").doc(userId).collection("Barang").doc(id));
      
      // Delete from PersediaanTotal
      batch.delete(_db.collection("Users").doc(userId).collection("PersediaanTotal").doc(id));
      
      // Delete related Pembelian documents
      QuerySnapshot pembelianDocs = await _db
          .collection("Users")
          .doc(userId)
          .collection("Pembelian")
          .where("BarangId", isEqualTo: id)
          .get();
          
      for (var doc in pembelianDocs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print("Error deleting document: $e");
      throw e;
    }
  }

}
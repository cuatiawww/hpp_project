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
    
    try {
      // 1. Mulai transaction/batch
      WriteBatch batch = _db.batch();

      // 2. Simpan data pembelian
      DocumentReference pembelianRef = _db
          .collection("Users")
          .doc(userId)
          .collection("Pembelian")
          .doc();
          
      batch.set(pembelianRef, {
        ...pembelianData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update stok di collection Barang
      DocumentReference barangRef = _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(pembelianData['BarangId']);

      // Cek apakah barang sudah ada
      DocumentSnapshot barangDoc = await barangRef.get();
      
      if (barangDoc.exists) {
        // Update stok jika barang sudah ada
        batch.update(barangRef, {
          'Jumlah': FieldValue.increment(pembelianData['Jumlah'] as int),
          'Price': pembelianData['Price'], // Update harga dengan harga terbaru
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Buat dokumen baru jika barang belum ada
        batch.set(barangRef, {
          'Name': pembelianData['Name'],
          'Tipe': pembelianData['Type'],
          'Jumlah': pembelianData['Jumlah'],
          'Price': pembelianData['Price'],
          'Satuan': pembelianData['Satuan'],
          'Tanggal': pembelianData['Tanggal'],
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // 4. Add to Riwayat
      DocumentReference riwayatRef = _db
          .collection("Users")
          .doc(userId)
          .collection("Riwayat")
          .doc();
          
      batch.set(riwayatRef, {
        'type': 'Pembelian',
        'name': pembelianData['Name'],
        'tipe': pembelianData['Type'],
        'jumlah': pembelianData['Jumlah'],
        'price': pembelianData['Price'],
        'satuan': pembelianData['Satuan'],
        'tanggal': pembelianData['Tanggal'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Commit batch operation
      await batch.commit();
      
    } catch (e) {
      print("Error in addPembelian: $e");
      throw e;
    }
}


  // Modifikasi method untuk mendapatkan pembelian
  Future<int> getTotalStok(String barangId) async {
    String userId = currentUserId;
    
    try {
      // 1. Ambil stok dari collection Barang
      final barangDoc = await _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(barangId)
          .get();

      if (!barangDoc.exists) {
        return 0;
      }

      return (barangDoc.data()?['Jumlah'] ?? 0) as int;

    } catch (e) {
      print("Error getting total stok: $e");
      throw e;
    }
}

// Method untuk mengupdate stok yang sudah ada
Future<void> updateStok(String barangId, Map<String, dynamic> updateData) async {
    String userId = currentUserId;
    
    try {
      await _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(barangId)
          .update({
        ...updateData,
        'LastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating stok: $e");
      throw e;
    }
}


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
  Future<Map<String, Map<String, dynamic>>> getAvailableStock() async {
    String userId = currentUserId;
    
    try {
      // 1. Ambil data dari collection Barang dan Pembelian
      final results = await Future.wait([
        _db.collection("Users").doc(userId).collection("Barang").get(),
        _db.collection("Users").doc(userId).collection("Pembelian").get(),
      ]);

      final barangDocs = results[0];
      final pembelianDocs = results[1];
      
      Map<String, Map<String, dynamic>> stockMap = {};

      // Proses data barang
      for (var doc in barangDocs.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Tipe']}'; // Gunakan kombinasi nama dan tipe sebagai key
        
        stockMap[key] = {
          'id': doc.id,
          'name': data['Name'],
          'tipe': data['Tipe'],
          'jumlah': data['Jumlah'] ?? 0,
          'price': data['Price'] ?? 0,
          'satuan': data['Satuan'],
        };
      }

      // Proses data pembelian
      for (var doc in pembelianDocs.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        
        if (stockMap.containsKey(key)) {
          // Update existing entry
          stockMap[key]!['jumlah'] = (stockMap[key]!['jumlah'] as int) + (data['Jumlah'] ?? 0);
          // Update price with the latest price from purchase
          stockMap[key]!['price'] = data['Price'] ?? stockMap[key]!['price'];
        } else {
          // Create new entry
          stockMap[key] = {
            'id': data['BarangId'],
            'name': data['Name'],
            'tipe': data['Type'],
            'jumlah': data['Jumlah'] ?? 0,
            'price': data['Price'] ?? 0,
            'satuan': data['Satuan'],
          };
        }
      }

      return stockMap;
    } catch (e) {
      print("Error getting available stock: $e");
      throw e;
    }
}
  
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
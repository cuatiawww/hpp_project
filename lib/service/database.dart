import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DatabaseMethods {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Modifikasi method addBarang
Future<void> addBarang(Map<String, dynamic> barangInfoMap, String id) async {
    String userId = currentUserId;
    
    if (!barangInfoMap.containsKey('Tanggal')) {
      barangInfoMap['Tanggal'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    final barangData = {
      ...barangInfoMap,
      'userId': userId,
      'isInitialInventory': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection("Users")
        .doc(userId)
        .collection("Barang")
        .doc(id)
        .set(barangData);
}

  // Modifikasi method untuk mendapatkan barang
 Stream<QuerySnapshot> getBarangDetails() {
    String userId = currentUserId;
    return _db.collection("Users")
        .doc(userId)
        .collection("Barang")
        .where('isInitialInventory', isEqualTo: true)  // Only get initial inventory items
        .snapshots();
}

  // Modifikasi method addPembelian
Future<void> addPembelian(Map<String, dynamic> pembelianData) async {
    String userId = currentUserId;
    
    try {
      // Gunakan tanggal hari ini jika tidak ada tanggal yang diberikan
      if (!pembelianData.containsKey('Tanggal')) {
        pembelianData['Tanggal'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      WriteBatch batch = _db.batch();
      
      // Simpan pembelian
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

      // Update atau buat barang baru
      DocumentReference barangRef = _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(pembelianData['BarangId']);

      DocumentSnapshot barangDoc = await barangRef.get();
      
      if (barangDoc.exists) {
        batch.update(barangRef, {
          'Jumlah': FieldValue.increment(pembelianData['Jumlah'] as int),
          'Price': pembelianData['Price'],
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
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

Future<Map<String, Map<String, dynamic>>> getPersediaanAkhir(String selectedMonth) async {
    final userId = currentUserId;
    final Map<String, Map<String, dynamic>> result = {};
    
    try {
      final selectedDate = DateTime.parse('$selectedMonth-01');
      final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      final selectedMonthEnd = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);
      
      // 1. Get initial inventory (Persediaan Awal) with date filtering
      final barangSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .where('isInitialInventory', isEqualTo: true)
          .get();

      // Process initial inventory with date check
      for (var doc in barangSnapshot.docs) {
        var data = doc.data();
        
        // Check if the item was created before or during the selected month
        String tanggal = data['Tanggal'] ?? '';
        if (tanggal.isEmpty || tanggal.compareTo(selectedMonthEnd) > 0) {
          continue; // Skip this item if it was created after the selected month
        }

        String key = '${data['Name']}_${data['Tipe']}';
        result[key] = {
          'id': doc.id,
          'Name': data['Name'],
          'Tipe': data['Tipe'],
          'Jumlah': data['Jumlah'] ?? 0,
          'Price': data['Price'],
          'Satuan': data['Satuan'],
          'Tanggal': data['Tanggal'],
        };
      }

      // 2. Add purchases with date filtering
      final pembelianSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("Pembelian")
          .where('Tanggal', isLessThanOrEqualTo: selectedMonthEnd)
          .get();

      for (var doc in pembelianSnapshot.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        
        if (result.containsKey(key)) {
          result[key]!['Jumlah'] = (result[key]!['Jumlah'] as int) + (data['Jumlah'] as int);
          if (data['Tanggal'].compareTo(result[key]!['Tanggal']) > 0) {
            result[key]!['Price'] = data['Price'];
            result[key]!['Tanggal'] = data['Tanggal'];
          }
        } else {
          // Only add purchase if it's in the selected month or before
          if (data['Tanggal'].compareTo(selectedMonthEnd) <= 0) {
            result[key] = {
              'id': data['BarangId'],
              'Name': data['Name'],
              'Tipe': data['Type'],
              'Jumlah': data['Jumlah'] ?? 0,
              'Price': data['Price'],
              'Satuan': data['Satuan'],
              'Tanggal': data['Tanggal'],
            };
          }
        }
      }

      // 3. Subtract sales with date filtering
      final penjualanSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("Penjualan")
          .where('tanggal', isLessThanOrEqualTo: selectedMonthEnd)
          .get();

      for (var doc in penjualanSnapshot.docs) {
        var data = doc.data();
        String key = '${data['namaBarang']}_${data['tipe']}';
        
        if (result.containsKey(key)) {
          int newJumlah = (result[key]!['Jumlah'] as int) - (data['jumlah'] as int);
          result[key]!['Jumlah'] = newJumlah;
        }
      }

      // Remove items with zero or negative stock
      result.removeWhere((key, value) => (value['Jumlah'] as int) <= 0);

      return result;
    } catch (e) {
      print('Error in getPersediaanAkhir: $e');
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
    
    try {
      WriteBatch batch = _db.batch();
      
      // Add to Penjualan collection
      DocumentReference penjualanRef = _db
          .collection("Users")
          .doc(userId)
          .collection("Penjualan")
          .doc();

      batch.set(penjualanRef, {
        ...penjualanData,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // TIDAK PERLU update stok barang di collection Barang
      // Karena itu adalah Persediaan Awal yang harus tetap
      
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

      await batch.commit();
    } catch (e) {
      print("Error in addPenjualan: $e");
      throw e;
    }
  }
  
  //GENERATEMONTHS
    List<String> generateMonthRange() {
    final now = DateTime.now();
    final List<String> months = [];
    
    // 6 bulan sebelumnya
    for (int i = 6; i >= 1; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('yyyy-MM').format(month));
    }
    
    // Bulan sekarang
    months.add(DateFormat('yyyy-MM').format(now));
    
    // 6 bulan kedepan
    for (int i = 1; i <= 6; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      months.add(DateFormat('yyyy-MM').format(month));
    }
    
    return months;
  }

//PENJUALAN
Future<Map<String, Map<String, dynamic>>> getAvailableStock() async {
  String userId = currentUserId;
  
  try {
    final results = await Future.wait([
      _db.collection("Users").doc(userId).collection("Barang").get(),
      _db.collection("Users").doc(userId).collection("Pembelian").get(),
      _db.collection("Users").doc(userId).collection("Penjualan").get(),
    ]);

    final barangDocs = results[0];
    final pembelianDocs = results[1];
    final penjualanDocs = results[2];
    
    Map<String, Map<String, dynamic>> stockMap = {};

    // 1. Proses Persediaan Awal
    for (var doc in barangDocs.docs) {
      var data = doc.data();
      if (data['isInitialInventory'] == true) { // Hanya ambil persediaan awal
        String key = '${data['Name']}_${data['Tipe']}';
        stockMap[key] = {
          'id': doc.id,
          'name': data['Name'],
          'tipe': data['Tipe'],
          'jumlah': data['Jumlah'] ?? 0,
          'price': data['Price'] ?? 0,
          'satuan': data['Satuan'],
        };
      }
    }

    // 2. Proses Pembelian (tambah ke stok)
    Map<String, int> pembelianTotal = {};
    for (var doc in pembelianDocs.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Type']}';
      
      // Tambahkan jumlah pembelian ke map total
      pembelianTotal[key] = (pembelianTotal[key] ?? 0) + (data['Jumlah'] as int);
      
      // Jika barang belum ada di stockMap, tambahkan
      if (!stockMap.containsKey(key)) {
        stockMap[key] = {
          'id': data['BarangId'],
          'name': data['Name'],
          'tipe': data['Type'],
          'jumlah': 0, // Mulai dari 0
          'price': data['Price'],
          'satuan': data['Satuan'],
        };
      }
    }

    // Update stok dengan total pembelian
    pembelianTotal.forEach((key, totalPembelian) {
      if (stockMap.containsKey(key)) {
        stockMap[key]!['jumlah'] = (stockMap[key]!['jumlah'] as int) + totalPembelian;
      }
    });

    // 3. Proses Penjualan (kurangi dari stok)
    Map<String, int> penjualanTotal = {};
    for (var doc in penjualanDocs.docs) {
      var data = doc.data();
      String key = '${data['namaBarang']}_${data['tipe']}';
      
      // Tambahkan jumlah penjualan ke map total
      penjualanTotal[key] = (penjualanTotal[key] ?? 0) + (data['jumlah'] as int);
    }

    // Update stok dengan total penjualan
    penjualanTotal.forEach((key, totalPenjualan) {
      if (stockMap.containsKey(key)) {
        stockMap[key]!['jumlah'] = (stockMap[key]!['jumlah'] as int) - totalPenjualan;
      }
    });

    // Hapus item dengan stok <= 0
    stockMap.removeWhere((key, value) => (value['jumlah'] as int) <= 0);

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
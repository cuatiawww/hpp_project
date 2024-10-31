import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CREATE
  Future<void> addBarang(Map<String, dynamic> barangInfoMap, String id) async {
    await _db.collection("Barang").doc(id).set(barangInfoMap);
    
    // Also add initial total to PersediaanTotal
    await _db.collection("PersediaanTotal").doc(id).set({
      'Name': barangInfoMap['Name'],
      'Tipe': barangInfoMap['Tipe'],
      'Jumlah': barangInfoMap['Jumlah'],
      'Price': barangInfoMap['Price'],
      'Satuan': barangInfoMap['Satuan'],
      'Tanggal': barangInfoMap['Tanggal'],
      'LastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Add Pembelian and update PersediaanTotal
  Future<void> addPembelian(Map<String, dynamic> pembelianData) async {
    // First add to Pembelian collection
    DocumentReference pembelianRef = await _db.collection("Pembelian").add(pembelianData);

    // Update PersediaanTotal
    try {
      final QuerySnapshot totalSnapshot = await _db
          .collection("PersediaanTotal")
          .where('Name', isEqualTo: pembelianData['Name'])
          .where('Tipe', isEqualTo: pembelianData['Type'])
          .get();

      if (totalSnapshot.docs.isNotEmpty) {
        // Update existing total
        await _db.collection("PersediaanTotal").doc(totalSnapshot.docs.first.id).update({
          'Jumlah': FieldValue.increment(pembelianData['Jumlah'] as int),
          'LastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new total entry
        await _db.collection("PersediaanTotal").add({
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
      // If updating PersediaanTotal fails, delete the Pembelian record
      await pembelianRef.delete();
      throw Exception('Failed to update total persediaan: $e');
    }
  }

  // READ
  Stream<QuerySnapshot> getBarangDetails() {
    return _db.collection("Barang").snapshots();
  }

  Stream<QuerySnapshot> getPembelianDetails() {
    return _db.collection("Pembelian").snapshots();
  }

  Stream<QuerySnapshot> getPersediaanTotal() {
    return _db.collection("PersediaanTotal").snapshots();
  }

  Stream<QuerySnapshot> getPembelianDetailsByMonth(String startDate, String endDate) {
    return _db
        .collection("Pembelian")
        .where("Tanggal", isGreaterThanOrEqualTo: startDate)
        .where("Tanggal", isLessThanOrEqualTo: endDate)
        .snapshots();
  }

  Stream<QuerySnapshot> getBarangByMonth(String startDate, String endDate) {
    return _db
        .collection("Barang")
        .where("Tanggal", isGreaterThanOrEqualTo: startDate)
        .where("Tanggal", isLessThanOrEqualTo: endDate)
        .snapshots();
  }

  // UPDATE
  Future<void> updateBarangDetail(String id, Map<String, dynamic> updateInfo) async {
    try {
      DocumentSnapshot doc = await _db.collection("Barang").doc(id).get();
      if (doc.exists) {
        await _db.collection("Barang").doc(id).update(updateInfo);
        
        // Also update PersediaanTotal
        final totalDoc = await _db.collection("PersediaanTotal").doc(id).get();
        if (totalDoc.exists) {
          await _db.collection("PersediaanTotal").doc(id).update({
            ...updateInfo,
            'LastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        throw Exception("Document with ID $id does not exist.");
      }
    } catch (e) {
      print("Error updating document: $e");
      throw e;
    }
  }

  // DELETE
  Future<void> deleteBarangDetail(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection("Barang").doc(id).get();
      if (doc.exists) {
        // Start a batch operation
        WriteBatch batch = _db.batch();
        
        // Delete from Barang collection
        batch.delete(_db.collection("Barang").doc(id));
        
        // Delete from PersediaanTotal
        batch.delete(_db.collection("PersediaanTotal").doc(id));
        
        // Get and delete related Pembelian documents
        QuerySnapshot pembelianDocs = await _db
            .collection("Pembelian")
            .where("BarangId", isEqualTo: id)
            .get();
            
        for (var pembelianDoc in pembelianDocs.docs) {
          batch.delete(pembelianDoc.reference);
        }
        
        // Commit the batch
        await batch.commit();
      } else {
        throw Exception("Document with ID $id does not exist.");
      }
    } catch (e) {
      print("Error deleting document: $e");
      throw e;
    }
  }

  // Get total persediaan for a specific period
  Future<Map<String, dynamic>> getTotalPersediaan(String startDate, String endDate) async {
    try {
      // Get persediaan awal
      final persAwalSnapshot = await _db
          .collection("Barang")
          .where('Tanggal', isLessThanOrEqualTo: startDate)
          .orderBy('Tanggal', descending: true)
          .get();

      // Get pembelian for the period
      final pembelianSnapshot = await _db
          .collection("Pembelian")
          .where('Tanggal', isGreaterThanOrEqualTo: startDate)
          .where('Tanggal', isLessThanOrEqualTo: endDate)
          .get();

      Map<String, Map<String, dynamic>> totals = {};

      // Process persediaan awal
      for (var doc in persAwalSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String key = '${data['Name']}_${data['Tipe']}';
        
        if (!totals.containsKey(key)) {
          totals[key] = {
            'Name': data['Name'],
            'Tipe': data['Tipe'],
            'PersAwal': data['Jumlah'],
            'Pembelian': 0,
            'Total': data['Jumlah'],
            'Satuan': data['Satuan'],
          };
        }
      }

      // Process pembelian
      for (var doc in pembelianSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String key = '${data['Name']}_${data['Type']}';
        
        if (!totals.containsKey(key)) {
          totals[key] = {
            'Name': data['Name'],
            'Tipe': data['Type'],
            'PersAwal': 0,
            'Pembelian': data['Jumlah'],
            'Total': data['Jumlah'],
            'Satuan': data['Satuan'],
          };
        } else {
          totals[key]!['Pembelian'] = (totals[key]!['Pembelian'] as int) + (data['Jumlah'] as int);
          totals[key]!['Total'] = (totals[key]!['PersAwal'] as int) + (totals[key]!['Pembelian'] as int);
        }
      }

      return {
        'details': totals,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      print("Error getting total persediaan: $e");
      throw e;
    }
  }
}
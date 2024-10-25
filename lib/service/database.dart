import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // CREATE
  Future<void> addBarang(Map<String, dynamic> barangInfoMap, String id) async {
    await FirebaseFirestore.instance.collection("Barang").doc(id).set(barangInfoMap);
  }

  // READ
  Stream<QuerySnapshot> getBarangDetails() {
    return FirebaseFirestore.instance.collection("Barang").snapshots();
  }

  Stream<QuerySnapshot> getPembelianDetails() {
    return FirebaseFirestore.instance.collection("Pembelian").snapshots();
  }

  // New method to get Pembelian details by month and year
  Stream<QuerySnapshot> getPembelianDetailsByMonth(int month, int year) {
    return FirebaseFirestore.instance
        .collection("Pembelian")
        .where("Month", isEqualTo: month)
        .where("Year", isEqualTo: year)
        .snapshots();
  }

  // UPDATE
  Future<void> updateBarangDetail(String id, Map<String, dynamic> updateInfo) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection("Barang").doc(id).get();
      if (doc.exists) {
        await FirebaseFirestore.instance.collection("Barang").doc(id).update(updateInfo);
      } else {
        throw Exception("Document with ID $id does not exist.");
      }
    } catch (e) {
      print("Error updating document: $e");
      // Handle the error appropriately (e.g., show a snackbar or alert)
    }
  }

  // DELETE
  Future<void> deleteBarangDetail(String id) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection("Barang").doc(id).get();
      if (doc.exists) {
        // Delete Barang document
        await FirebaseFirestore.instance.collection("Barang").doc(id).delete();

        // Also delete corresponding Pembelian documents
        await deletePembelianDetailByBarangId(id);
      } else {
        throw Exception("Document with ID $id does not exist.");
      }
    } catch (e) {
      print("Error deleting document: $e");
      // Handle the error appropriately
    }
  }

  // DELETE Pembelian by Barang ID
  Future<void> deletePembelianDetailByBarangId(String barangId) async {
    try {
      QuerySnapshot pembelianSnapshot = await FirebaseFirestore.instance
          .collection("Pembelian")
          .where("BarangId", isEqualTo: barangId)
          .get();

      // Delete each document in the Pembelian collection matching the Barang ID
      for (var doc in pembelianSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error deleting pembelian documents: $e");
      // Handle the error appropriately
    }
  }
}

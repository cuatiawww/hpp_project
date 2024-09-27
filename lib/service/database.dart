import 'package:cloud_firestore/cloud_firestore.dart';

// class FirebaseDatabaseHelper {
//   Future<List<Map<String, dynamic>>> getFinalInventory() async {
//     // Initialize Firestore
//     FirebaseFirestore firestore = FirebaseFirestore.instance;

//     // Get all items in barang collection
//     QuerySnapshot barangSnapshot = await firestore.collection('barang').get();
//     List<Map<String, dynamic>> finalInventory = [];

//     for (var barangDoc in barangSnapshot.docs) {
//       // Get initial data of the item, safely accessing nullable values
//       var barangData = barangDoc.data() as Map<String, dynamic>?;
//       var initialQuantity = barangData?['initial_quantity'] ?? 0;
//       var initialPrice = barangData?['price']?.toDouble() ?? 0.0;

//       // Fetch purchase records related to this item (barang)
//       QuerySnapshot purchaseSnapshot = await firestore
//           .collection('purchase')
//           .where('barang_id', isEqualTo: barangDoc.id)
//           .get();

//       int totalPurchasedQuantity = 0;
//       double totalPrice = 0.0;

//       // Calculate total purchased quantity and average price from purchase records
//       for (var purchaseDoc in purchaseSnapshot.docs) {
//         var purchaseData = purchaseDoc.data() as Map<String, dynamic>?;
//         totalPurchasedQuantity += (purchaseData?['quantity'] as int?) ?? 0;
//         totalPrice += ((purchaseData?['price']?.toDouble() ?? 0.0) *
//             (purchaseData?['quantity'] ?? 0));
//       }

//       double averagePrice = totalPurchasedQuantity > 0
//           ? totalPrice / totalPurchasedQuantity
//           : initialPrice;

//       // Add combined data to the final inventory list
//       finalInventory.add({
//         'id': barangDoc.id,
//         'name': barangData?['name'] ?? '',
//         'initial_quantity': initialQuantity,
//         'purchased_quantity': totalPurchasedQuantity,
//         'total_quantity': initialQuantity + totalPurchasedQuantity,
//         'initial_price': initialPrice,
//         'average_price': averagePrice,
//       });
//     }

//     return finalInventory;
//   }
// }

class DatabaseMethods {
  // CREATE
  Future<void> addBarang(Map<String, dynamic> barangInfoMap, String id) async {
    await FirebaseFirestore.instance.collection("Barang").doc(id).set(barangInfoMap);
  }

  Future<void> addNewPurchase(Map<String, dynamic> newBarang) async {
    await FirebaseFirestore.instance.collection('purchases').add(newBarang);
  }

  // READ

  Stream<QuerySnapshot> getPurchases() {
    return FirebaseFirestore.instance.collection('purchases').snapshots();
  }

  Stream<QuerySnapshot> getBarangDetails() {
    return FirebaseFirestore.instance.collection("Barang").snapshots();
  }

  Stream<QuerySnapshot> getReportPembelian() {
    return FirebaseFirestore.instance.collection('purchases').snapshots();
  }

  // DELETE
  Future<void> deletePersAkhirData(String docId) async {
    await FirebaseFirestore.instance.collection('pers_akhir').doc(docId).delete();
  }

  // UPDATE

  Future<void> updateBarangDetail(String id, Map<String, dynamic> updateInfo) async {
    await FirebaseFirestore.instance.collection("Barang").doc(id).update(updateInfo);
  }
}

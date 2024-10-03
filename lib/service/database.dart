import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> deleteBarang(String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('Barang').doc(itemId).delete();
      print("Item deleted successfully.");
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  Future<void> logDeletion(String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('purchases').add({
        'item_id': itemId,
        'action': 'delete',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Deletion logged successfully.");
    } catch (e) {
      print("Failed to log deletion: $e");
    }
  }

  Future<void> logQuantityRemoval(String itemId, int quantityRemoved) async {
    try {
      await FirebaseFirestore.instance.collection('purchases').add({
        'item_id': itemId,
        'action': 'remove',
        'quantity': -quantityRemoved,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Quantity removal logged successfully.");
    } catch (e) {
      print("Failed to log quantity removal: $e");
    }
  }

  Future<void> removeQuantity(String itemId, int quantity) async {
    DocumentReference itemRef = FirebaseFirestore.instance.collection('Barang').doc(itemId);
    await itemRef.update({
      'Jumlah': FieldValue.increment(-quantity), // Decrease the quantity
    });
  }

  // UPDATE
  Future<void> updateBarangDetail(String id, Map<String, dynamic> updateInfo) async {
    await FirebaseFirestore.instance.collection("Barang").doc(id).update(updateInfo);
  }

  Stream<List<Map<String, dynamic>>> getFinalInventory() async* {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    while (true) {
      QuerySnapshot barangSnapshot = await firestore.collection('Barang').get();
      List<Map<String, dynamic>> finalInventory = [];

      for (var barangDoc in barangSnapshot.docs) {
        var barangData = barangDoc.data() as Map<String, dynamic>? ?? {};
        var initialQuantity = barangData['Jumlah'] ?? 0;
        var initialPrice = barangData['Price']?.toDouble() ?? 0.0;

        QuerySnapshot purchaseSnapshot = await firestore
            .collection('purchases')
            .where('item_id', isEqualTo: barangDoc.id)
            .get();

        int totalPurchasedQuantity = 0;
        double totalPrice = 0.0;

        for (var purchaseDoc in purchaseSnapshot.docs) {
          var purchaseData = purchaseDoc.data() as Map<String, dynamic>? ?? {};
          totalPurchasedQuantity += (purchaseData['quantity'] as int?) ?? 0; // Pastikan sesuai
          totalPrice += (purchaseData['price']?.toDouble() ?? 0.0) * (purchaseData['quantity'] ?? 0);
        }

        double averagePrice = totalPurchasedQuantity > 0
            ? totalPrice / totalPurchasedQuantity
            : initialPrice;

        finalInventory.add({
          'id': barangDoc.id,
          'name': barangData['Name'] ?? '',
          'initial_quantity': initialQuantity,
          'purchased_quantity': totalPurchasedQuantity,
          'total_quantity': initialQuantity + totalPurchasedQuantity,
          'initial_price': initialPrice,
          'average_price': averagePrice,
        });
      }

      yield finalInventory;
      await Future.delayed(Duration(seconds: 1));
    }
  }
 }

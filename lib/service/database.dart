import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // CREATE
  Future addBarang(
      Map<String, dynamic> barangInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Barang")
        .doc(id)
        .set(barangInfoMap);
  }

// // READ
//   Future<Stream<QuerySnapshot>> getEmployeeDetails() async {
//     return await FirebaseFirestore.instance.collection("Employee").snapshots();
//   }

// // UPDATE
//   Future updateEmployeeDetail(String id, Map<String, dynamic> updateInfo)async{
//     return await FirebaseFirestore.instance.collection("Employee").doc(id).update(updateInfo);
//   }

// // DELETE
//     Future deleteEmployeeDetail(String id)async{
//     return await FirebaseFirestore.instance.collection("Employee").doc(id).delete();
//   }
}

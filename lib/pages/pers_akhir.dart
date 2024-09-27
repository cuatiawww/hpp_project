// import 'package:flutter/material.dart';
// import 'package:hpp_project/service/database.dart'; // Import the database helper

// class PersAkhirPage extends StatefulWidget {
//   @override
//   _PersAkhirPageState createState() => _PersAkhirPageState();
// }

// class _PersAkhirPageState extends State<PersAkhirPage> {
//   List<Map<String, dynamic>> finalInventory = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchFinalInventory();
//   }

//   Future<void> fetchFinalInventory() async {
//     FirebaseDatabaseHelper dbHelper = FirebaseDatabaseHelper();
//     var inventory = await dbHelper.getFinalInventory();
    
//     setState(() {
//       finalInventory = inventory;
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Pers Akhir'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 columns: [
//                   DataColumn(label: Text('ID')),
//                   DataColumn(label: Text('Name')),
//                   DataColumn(label: Text('Initial Quantity')),
//                   DataColumn(label: Text('Purchased Quantity')),
//                   DataColumn(label: Text('Total Quantity')),
//                   DataColumn(label: Text('Initial Price')),
//                   DataColumn(label: Text('Average Price')),
//                 ],
//                 rows: finalInventory.map((item) {
//                   return DataRow(cells: [
//                     DataCell(Text(item['id'].toString())),
//                     DataCell(Text(item['name'])),
//                     DataCell(Text(item['initial_quantity'].toString())),
//                     DataCell(Text(item['purchased_quantity'].toString())),
//                     DataCell(Text(item['total_quantity'].toString())),
//                     DataCell(Text(item['initial_price'].toString())),
//                     DataCell(Text(item['average_price'].toString())),
//                   ]);
//                 }).toList(),
//               ),
//             ),
//     );
//   }
// }

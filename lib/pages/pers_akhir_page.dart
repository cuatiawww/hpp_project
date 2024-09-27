import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';

class PersAkhirPage extends StatefulWidget {
  @override
  _PersAkhirPageState createState() => _PersAkhirPageState();
}

class _PersAkhirPageState extends State<PersAkhirPage> {
  Stream<List<Map<String, dynamic>>>? persAkhirStream;

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    persAkhirStream = DatabaseMethods().getFinalInventory(); // Get stream from Database
  }

  void deleteItem(String itemId) async {
    await DatabaseMethods().deleteBarang(itemId);
    await DatabaseMethods().logDeletion(itemId);
    getData(); // Refresh the data
  }

  Widget buildPersAkhirList() {
    return StreamBuilder<List<Map<String, dynamic>>>( 
      stream: persAkhirStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.isEmpty) {
          return Center(child: Text("Tidak ada data persediaan akhir yang ditemukan."));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blueAccent),
            columnSpacing: 20,
            dataTextStyle: TextStyle(color: Colors.black),
            headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: [
              DataColumn(label: Text('Nama Barang')),
              DataColumn(label: Text('Jumlah Barang')),
              DataColumn(label: Text('Satuan')),
              DataColumn(label: Text('Harga')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: snapshot.data!.map((item) {
              String name = item['name'] ?? '';
              int jumlah = (item['initial_quantity'] as int) + (item['purchased_quantity'] as int);
              int price = (item['average_price'] as num).toInt();
              String satuan = 'Pcs';
              int total = jumlah * price;

              return DataRow(cells: [
                DataCell(Text(name)),
                DataCell(Text(jumlah.toString())),
                DataCell(Text(satuan)),
                DataCell(Text('Rp $price')),
                DataCell(Text('Rp $total')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          _removeQuantityDialog(item['id'], jumlah);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deleteItem(item['id']);
                        },
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  void _removeQuantityDialog(String itemId, int currentQuantity) {
    TextEditingController quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Hapus Jumlah Barang"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Jumlah yang ingin dihapus"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                int quantityToRemove = int.tryParse(quantityController.text) ?? 0;
                if (quantityToRemove > 0 && quantityToRemove <= currentQuantity) {
                  await DatabaseMethods().removeQuantity(itemId, quantityToRemove);
                  await DatabaseMethods().logQuantityRemoval(itemId, quantityToRemove);
                  getData(); // Refresh the data
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Jumlah tidak valid!"),
                  ));
                }
              },
              child: Text("Hapus"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Batal"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildPersAkhirList(),
      ),
    );
  }
}

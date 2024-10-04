import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';

class PersAkhirPage extends StatefulWidget {
  @override
  _PersAkhirPageState createState() => _PersAkhirPageState();
}

class _PersAkhirPageState extends State<PersAkhirPage> {
  Stream<QuerySnapshot>? barangStream;
  Stream<QuerySnapshot>? pembelianStream;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    barangStream = DatabaseMethods().getBarangDetails();
    pembelianStream = DatabaseMethods().getPembelianDetails();
  }

  Widget buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: barangStream,
      builder: (context, barangSnapshot) {
        if (!barangSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        Map<String, Map<String, dynamic>> barangReference = {};
        for (var barang in barangSnapshot.data!.docs) {
          var barangData = barang.data() as Map<String, dynamic>;
          barangReference[barang.id] = {
            "Name": barangData["Name"],
            "Satuan": barangData["Satuan"],
            "docId": barang.id,
          };
        }

        return StreamBuilder<QuerySnapshot>(
          stream: pembelianStream,
          builder: (context, pembelianSnapshot) {
            if (!pembelianSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            Map<String, Map<String, dynamic>> combinedData = {};

            // Proses data persediaan awal
            for (var barang in barangSnapshot.data!.docs) {
              var barangData = barang.data() as Map<String, dynamic>;
              var barangId = barang.id;
              var tipe = barangData["Tipe"] ?? "Default";
              var key = '${barangId}_$tipe';

              combinedData[key] = {
                "id": barangId,
                "Name": barangData["Name"],
                "Satuan": barangData["Satuan"],
                "Jumlah": barangData["Jumlah"] ?? 0,
                "Price": barangData["Price"] ?? 0,
                "Tipe": tipe,
                "isOriginal": true,
                "docId": barangId,
              };
            }

            // Menyimpan ID dokumen pembelian berdasarkan kombinasi BarangId dan Type
            Map<String, List<String>> pembelianDocs = {};
            
            // Proses data pembelian
            for (var pembelian in pembelianSnapshot.data!.docs) {
              var pembelianData = pembelian.data() as Map<String, dynamic>;
              var barangId = pembelianData["BarangId"];
              var tipe = pembelianData["Type"];
              var key = '${barangId}_$tipe';

              // Menyimpan ID dokumen pembelian
              if (!pembelianDocs.containsKey(key)) {
                pembelianDocs[key] = [];
              }
              pembelianDocs[key]!.add(pembelian.id);

              var barangRef = barangReference[barangId];

              if (combinedData.containsKey(key)) {
                combinedData[key]!["Jumlah"] = 
                    (combinedData[key]!["Jumlah"] as int) + 
                    (pembelianData["Jumlah"] as int);
                
                if (pembelianData["Price"] != null) {
                  combinedData[key]!["Price"] = pembelianData["Price"];
                }
              } else {
                combinedData[key] = {
                  "id": barangId,
                  "Name": barangRef?["Name"] ?? "N/A",
                  "Satuan": barangRef?["Satuan"] ?? "N/A",
                  "Jumlah": pembelianData["Jumlah"] ?? 0,
                  "Price": pembelianData["Price"] ?? 0,
                  "Tipe": tipe,
                  "isOriginal": false,
                  "docId": pembelian.id,
                  "pembelianIds": pembelianDocs[key],
                };
              }
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Nama Barang")),
                  DataColumn(label: Text("Tipe")),
                  DataColumn(label: Text("Jumlah")),
                  DataColumn(label: Text("Satuan")),
                  DataColumn(label: Text("Harga")),
                  DataColumn(label: Text("Total")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: combinedData.entries.map((entry) {
                  final data = entry.value;
                  final total = (data["Jumlah"] as int) * (data["Price"] as int);

                  return DataRow(
                    cells: [
                      DataCell(Text(data["Name"])),
                      DataCell(Text(data["Tipe"].toString())),
                      DataCell(Text(data["Jumlah"].toString())),
                      DataCell(Text(data["Satuan"])),
                      DataCell(Text('Rp ${data["Price"]}')),
                      DataCell(Text('Rp $total')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editBarang(data, entry.key),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteBarang(data, entry.key),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editBarang(Map<String, dynamic> data, String key) async {
    TextEditingController jumlahController = 
        TextEditingController(text: data["Jumlah"].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Jumlah Barang"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama: ${data['Name']}"),
            Text("Tipe: ${data['Tipe']}"),
            SizedBox(height: 16),
            TextField(
              controller: jumlahController,
              decoration: InputDecoration(
                labelText: "Jumlah",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              if (data["isOriginal"] == true) {
                // Update barang di collection Barang
                await DatabaseMethods().updateBarangDetail(
                  data["docId"],
                  {"Jumlah": int.parse(jumlahController.text)},
                );
              } else {
                // Update semua dokumen pembelian yang terkait
                List<String>? pembelianIds = data["pembelianIds"] as List<String>?;
                if (pembelianIds != null) {
                  int newJumlahPerDoc = int.parse(jumlahController.text) ~/ pembelianIds.length;
                  for (String pembelianId in pembelianIds) {
                    await FirebaseFirestore.instance
                        .collection("Pembelian")
                        .doc(pembelianId)
                        .update({"Jumlah": newJumlahPerDoc});
                  }
                }
              }
              Navigator.pop(context);
              setState(() {
                loadData();
              });
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBarang(Map<String, dynamic> data, String key) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text("Anda yakin ingin menghapus barang ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Hapus"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      if (data["isOriginal"] == true) {
        // Hapus barang dari collection Barang
        await DatabaseMethods().deleteBarangDetail(data["docId"]);
      } else {
        // Hapus semua dokumen pembelian yang terkait
        List<String>? pembelianIds = data["pembelianIds"] as List<String>?;
        if (pembelianIds != null) {
          for (String pembelianId in pembelianIds) {
            await FirebaseFirestore.instance
                .collection("Pembelian")
                .doc(pembelianId)
                .delete();
          }
        }
      }
      setState(() {
        loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildTable(),
      ),
    );
  }
}
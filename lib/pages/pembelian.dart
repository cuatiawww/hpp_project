import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  String? selectedBarang;
  String? selectedType;
  TextEditingController unitController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  Stream<QuerySnapshot>? barangStream;
  bool isDifferentType = false; // New variable to indicate if the type is different

  @override
  void initState() {
    super.initState();
    loadBarangData();
  }

  loadBarangData() {
    barangStream = DatabaseMethods().getBarangDetails(); // Ensure this is correct
    setState(() {});
  }

  Widget barangDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: barangStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        List<DropdownMenuItem<String>> barangItems = [];
        snapshot.data!.docs.forEach((doc) {
          barangItems.add(
            DropdownMenuItem(
              value: doc.id,
              child: Text(doc["Name"]),
            ),
          );
        });

        return DropdownButton<String>(
          isExpanded: true,
          hint: Text("Pilih Barang"),
          value: selectedBarang,
          onChanged: (newValue) {
            setState(() {
              selectedBarang = newValue!;
              priceController.clear(); // Clear previous price
              typeController.clear(); // Clear previous type
              isDifferentType = false; // Reset the different type flag
            });
            fetchSelectedBarangDetails(newValue!); // Fetch selected barang details
          },
          items: barangItems,
        );
      },
    );
  }

  // Fetch details of the selected barang
  Future<void> fetchSelectedBarangDetails(String barangId) async {
    try {
      DocumentSnapshot selectedDoc = await FirebaseFirestore.instance.collection("Barang").doc(barangId).get();
      if (selectedDoc.exists) {
        // Set the price and type based on the selected barang
        priceController.text = selectedDoc["Price"].toString();
        typeController.text = selectedDoc["Tipe"];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching data: ${e.toString()}")));
    }
  }

  Future<void> tambahBarang() async {
    if (selectedBarang == null || unitController.text.isEmpty || (isDifferentType && (typeController.text.isEmpty || priceController.text.isEmpty))) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harap isi semua field")));
        return;
    }

    int additionalUnits = int.parse(unitController.text);
    int newPrice = isDifferentType ? int.parse(priceController.text) : 0; // Use new price if type is different

    try {
        // Get the selected barang details
        DocumentSnapshot selectedDoc = await FirebaseFirestore.instance.collection("Barang").doc(selectedBarang).get();

        if (!selectedDoc.exists) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Barang tidak ditemukan.")));
            return;
        }

        // Check if the selected barang already exists in the Pembelian collection
        QuerySnapshot pembelianQuery = await FirebaseFirestore.instance.collection("Pembelian")
            .where("BarangId", isEqualTo: selectedBarang)
            .where("Type", isEqualTo: isDifferentType ? typeController.text : selectedDoc["Tipe"]) // Check if the type is the same
            .get();

        if (pembelianQuery.docs.isNotEmpty) {
            // If there's an existing entry with the same barang and type
            DocumentSnapshot existingDoc = pembelianQuery.docs.first;

            // Update the quantity
            await existingDoc.reference.update({
                "Jumlah": existingDoc["Jumlah"] + additionalUnits,
                "Timestamp": FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Jumlah barang berhasil diperbarui!")));
        } else {
            // If no existing entry, create a new document in Pembelian collection with item type
            newPrice = isDifferentType ? newPrice : selectedDoc["Price"];

            await FirebaseFirestore.instance.collection("Pembelian").add({
                "BarangId": selectedBarang,
                "Jumlah": additionalUnits,
                "Price": newPrice,
                "Type": isDifferentType ? typeController.text : selectedDoc["Tipe"], // Use new type if it's different
                "Timestamp": FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Barang berhasil ditambahkan!")));
        }

        // Clear the input fields after submission
        unitController.clear();
        selectedBarang = null;
        typeController.clear();
        priceController.clear();
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pembelian Barang")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            barangDropdown(),
            SizedBox(height: 20),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Jumlah Unit",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isDifferentType,
                  onChanged: (value) {
                    setState(() {
                      isDifferentType = value!;
                      if (!isDifferentType) {
                        priceController.clear(); // Clear price if type is the same
                      }
                    });
                  },
                ),
                Text("Type berbeda")
              ],
            ),
            if (isDifferentType) ...[
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: "Type Barang (input jika berbeda)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Harga per Unit",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Harga per Unit (tidak bisa diubah)",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                keyboardType: TextInputType.number,
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: tambahBarang,
              child: Text("Tambahkan Barang"),
            ),
          ],
        ),
      ),
    );
  }
}

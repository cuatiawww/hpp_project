  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';

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
  TextEditingController tanggalController = TextEditingController();
  Stream<QuerySnapshot>? barangStream;
  bool isDifferentType = false;
  DateTime selectedDate = DateTime.now();

    @override
    void initState() {
    super.initState();
    loadBarangData();
    tanggalController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
  }

    loadBarangData() {
      barangStream = DatabaseMethods().getBarangDetails(); // Ensure this is correct
      setState(() {});
    }
    Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        tanggalController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
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
    if (selectedBarang == null || unitController.text.isEmpty || tanggalController.text.isEmpty ||
        (isDifferentType && (typeController.text.isEmpty || priceController.text.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harap isi semua field")));
      return;
    }

    int additionalUnits = int.parse(unitController.text);
    int newPrice = isDifferentType ? int.parse(priceController.text) : 0;

    try {
      DocumentSnapshot selectedDoc = await FirebaseFirestore.instance.collection("Barang").doc(selectedBarang).get();
      if (!selectedDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Barang tidak ditemukan.")));
        return;
      }

      // Update existing Barang document
      await FirebaseFirestore.instance.collection("Barang").doc(selectedBarang).update({
        "Jumlah": FieldValue.increment(additionalUnits),
        "Tanggal": tanggalController.text,
      });

      // Add new Pembelian document
      await FirebaseFirestore.instance.collection("Pembelian").add({
        "BarangId": selectedBarang,
        "Jumlah": additionalUnits,
        "Price": isDifferentType ? newPrice : selectedDoc["Price"],
        "Type": isDifferentType ? typeController.text : selectedDoc["Tipe"],
        "Timestamp": FieldValue.serverTimestamp(),
        "Tanggal": tanggalController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Barang berhasil ditambahkan!")));

      unitController.clear();
      selectedBarang = null;
      typeController.clear();
      priceController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }
    @override
Widget build(BuildContext context) {
    return Scaffold(
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
                        priceController.clear();
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
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: tanggalController,
                  decoration: InputDecoration(
                    labelText: "Tanggal",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
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

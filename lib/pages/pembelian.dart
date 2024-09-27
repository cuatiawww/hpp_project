import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';

class Pembelian extends StatefulWidget {
  const Pembelian({super.key});

  @override
  State<Pembelian> createState() => _PembelianState();
}

class _PembelianState extends State<Pembelian> {
  String? selectedBarang;
  List<DocumentSnapshot> barangList = [];
  TextEditingController jumlahController = TextEditingController();
  TextEditingController hargaController = TextEditingController();
  String satuan = ""; // Field for storing the satuan value

  @override
  void initState() {
    super.initState();
    fetchBarangList();
  }

  fetchBarangList() async {
    DatabaseMethods().getBarangDetails().listen((QuerySnapshot snapshot) {
      setState(() {
        barangList = snapshot.docs;
      });
    });
  }

 void addBarang() async {
  if (selectedBarang != null &&
      jumlahController.text.isNotEmpty &&
      hargaController.text.isNotEmpty) {
    // Fetching the selected barang details
    DocumentSnapshot selectedDocument = barangList.firstWhere(
      (doc) => doc.id == selectedBarang,
      orElse: () => throw Exception("Barang tidak ditemukan"),
    );

    Map<String, dynamic>? selectedData = selectedDocument.data() as Map<String, dynamic>?;

    String barangName = selectedData?['Name'] ?? 'Nama tidak ditemukan';

    Map<String, dynamic> newBarang = {
      "Id": selectedBarang,
      "Jumlah": int.parse(jumlahController.text),
      "Satuan": satuan,
      "Harga": int.parse(hargaController.text),
      "Name": barangName, // Include the name of the barang
      "Timestamp": FieldValue.serverTimestamp(),
    };

    await DatabaseMethods().addNewPurchase(newBarang);

    // Show success alert with item details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("Barang berhasil ditambahkan:\n\n"
              "Nama: $barangName\n"
              "Jumlah: ${jumlahController.text} pcs\n"
              "Harga: Rp ${hargaController.text}"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Close the Pembelian page as well
              },
            ),
          ],
        );
      },
    );
  } else {
    // Handle error
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text("Harap isi semua field dengan benar."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

  Widget buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedBarang,
        hint: Text("Pilih Barang"),
        isExpanded: true,
        underline: SizedBox(), // Menghilangkan garis bawah
        items: barangList.map((DocumentSnapshot ds) {
          return DropdownMenuItem<String>(
            value: ds.id,
            child: Text(ds["Name"]), // Assuming the Firestore field is 'Name'
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedBarang = value;
            satuan = value != null
                ? (barangList.firstWhere((doc) => doc.id == value)["Satuan"] ?? "")
                : ""; // Set satuan based on selected barang
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nama Barang",
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              buildDropdown(),
              SizedBox(height: 20.0),
              Text(
                "Satuan",
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: TextEditingController(text: satuan),
                  readOnly: true, // Make it non-editable
                  decoration: InputDecoration(
                    hintText: 'Satuan',
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                "Jumlah",
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: jumlahController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                "Harga per Satuan",
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: hargaController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan harga per satuan',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 30.0),
              Center(
                child: ElevatedButton(
                  onPressed: addBarang,
                  child: Text("Tambah Barang"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

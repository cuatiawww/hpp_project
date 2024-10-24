import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_calculation_page.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/input_pers_awal.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pembelian.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/service/database.dart';

class PersAwal extends StatefulWidget {
  const PersAwal({super.key});

  @override
  State<PersAwal> createState() => _PersAwalState();
}

class _PersAwalState extends State<PersAwal> {
  List<Tab> myTab = [
    Tab(text: 'P. Awal'),
    Tab(text: 'Pembelian'),
    Tab(text: 'P. Akhir'),
  ];

  Stream<QuerySnapshot>? persAwalStream;

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  getontheload() {
    persAwalStream = DatabaseMethods().getBarangDetails();
    setState(() {});
  }

 Widget allBarangDetails() {
  return StreamBuilder<QuerySnapshot>(
    stream: persAwalStream,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.data!.docs.isEmpty) {
        return Center(child: Text("Tidak ada data barang yang ditemukan."));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          DocumentSnapshot ds = snapshot.data!.docs[index];
          Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;

          String name = data != null && data.containsKey("Name") ? data["Name"] : "Nama tidak ada";
          String type = data != null && data.containsKey("Tipe") ? data["Tipe"] : "Tipe tidak ada"; // Retrieve Tipe
          int jumlah = data != null && data.containsKey("Jumlah") ? data["Jumlah"] : 0;
          int pricePerItem = data != null && data.containsKey("Price") ? data["Price"] : 0;
          String satuan = data != null && data.containsKey("Satuan") ? data["Satuan"] : "Satuan tidak ada";
          int totalPrice = jumlah * pricePerItem;

          return Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.black),
              ),
              leading: GestureDetector(
                onTap: () {
                  EditBarangDetail(ds);
                },
                child: Icon(Icons.edit),
              ),
              title: Text(
                '$name ($type)', // Display name with type
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 23),
              ),
              subtitle: Text(
                '$jumlah $satuan - Rp ${pricePerItem}/$satuan',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
              ),
              trailing: Text(
                'Rp $totalPrice',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: myTab.length,
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => InputPersAwal()));
              },
              child: Icon(Icons.add),
            ),
            SizedBox(height: 16),
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HPPCalculationPage()));
              },
              label: Text('Hitung HPP'),
              icon: Icon(Icons.calculate),
            ),
          ],
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Perusahaan Dagang',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: TabBar(
              indicatorColor: Color(0xFFFFFFFF),
              indicatorPadding: EdgeInsets.all(5),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Color(0xFFFFFFFF),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
              tabs: myTab,
            ),
          ),
          backgroundColor: Color(0xFF080C67),
        ),
        body: TabBarView(
          children: [
            allBarangDetails(),
            PembelianPage(),
            PersAkhirPage(),
          ],
        ),
      ),
    );
  }

  Future<void> EditBarangDetail(DocumentSnapshot ds) {
    TextEditingController nameController = TextEditingController(text: ds["Name"]);
    TextEditingController priceController = TextEditingController(text: ds["Price"].toString());
    TextEditingController jumlahController = TextEditingController(text: ds["Jumlah"].toString());
    TextEditingController tipeController = TextEditingController(text: ds["Tipe"] ?? ""); // Default to empty string if null

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Barang"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama Barang", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: nameController,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              Text("Harga per Pcs", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: priceController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Text("Jumlah", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: jumlahController,
                decoration: InputDecoration(border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: tipeController,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Map<String, dynamic> updateInfo = {
                "Name": nameController.text,
                "Price": int.parse(priceController.text),
                "Jumlah": int.parse(jumlahController.text),
                "Tipe": tipeController.text, // Include Tipe in update
              };
              try {
                await DatabaseMethods().updateBarangDetail(ds.id, updateInfo);
                Navigator.pop(context);
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Error"),
                    content: Text("Failed to update data: ${e.toString()}"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Ok"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/pages/input_pers_awal.dart';
import 'package:hpp_project/pages/pembelian.dart';
import 'package:hpp_project/pages/pers_akhir_page.dart';
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

  Stream<QuerySnapshot>? persAwalStream; // Perbaiki tipe stream

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  getontheload() {
    persAwalStream = DatabaseMethods().getBarangDetails(); // Perbaiki pemanggilan
    setState(() {});
  }

  Widget allBarangDetails() {
  return StreamBuilder<QuerySnapshot>(
    stream: persAwalStream,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      // Tambahkan log untuk melihat berapa banyak dokumen yang diterima
      print("Jumlah dokumen: ${snapshot.data!.docs.length}");

      if (snapshot.data!.docs.isEmpty) {
        return Center(child: Text("Tidak ada data barang yang ditemukan."));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          DocumentSnapshot ds = snapshot.data!.docs[index];
          int jumlah = ds["Jumlah"]; 
          int pricePerItem = ds["Price"]; 
          String satuan = ds["Satuan"]; 
          int totalPrice = jumlah * pricePerItem;

          return Container(
            child: Column(
              children: [
                Padding(
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
                      ds["Name"],
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 23),
                    ),
                    subtitle: Text(
                      '$jumlah $satuan - Rp ${pricePerItem}/$satuan',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 12),
                    ),
                    trailing: Text(
                      'Rp $totalPrice',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                  ),
                ),
              ],
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => InputPersAwal()));
          },
          child: Icon(Icons.add),
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
            // P. Awal Tab
            allBarangDetails(),
            // Pembelian Tab
            Pembelian(),
            // P. Akhir Tab
            PersAkhirPage()
          ],
        ),
      ),
    );
  }

  Future<void> EditBarangDetail(DocumentSnapshot ds) {
    TextEditingController nameController = TextEditingController(text: ds["Name"]);
    TextEditingController priceController = TextEditingController(text: ds["Price"].toString());
    TextEditingController jumlahController = TextEditingController(text: ds["Jumlah"].toString());

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
              };
              try {
                // Attempt to update the document
                await DatabaseMethods().updateBarangDetail(ds.id, updateInfo);
                Navigator.pop(context);
              } catch (e) {
                // Show an error message if the update fails
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

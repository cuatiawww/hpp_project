import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';

class ReportPembelian extends StatefulWidget {
  const ReportPembelian({super.key});

  @override
  State<ReportPembelian> createState() => _ReportPembelianState();
}

class _ReportPembelianState extends State<ReportPembelian> {
  Stream<QuerySnapshot>? reportStream;

  @override
  void initState() {
    super.initState();
    getReportData();
  }

  getReportData() {
    reportStream = DatabaseMethods().getPurchases();
    reportStream?.listen((snapshot) {
      snapshot.docs.forEach((doc) {
        print('Document ID: ${doc.id}, Data: ${doc.data()}');
      });
    });
  }

  Widget buildReportList() {
    return StreamBuilder<QuerySnapshot>(
      stream: reportStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print("Data ditemukan: ${snapshot.data!.docs.length} dokumen");
          for (var doc in snapshot.data!.docs) {
            print("Dokumen ID: ${doc.id}, Data: ${doc.data()}");
          }
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Tidak ada laporan pembelian yang ditemukan."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data!.docs[index];

            Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;

            String name = data?["Name"] ?? "Nama tidak ditemukan";
            int jumlah = data?["Jumlah"] ?? 0;
            int harga = data?["Harga"] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Container(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: Colors.black),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 23),
                  ),
                  subtitle: Text(
                    '$jumlah pcs',
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Rp $harga',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Laporan Pembelian',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF080C67),
      ),
      body: buildReportList(),
    );
  }
}

// lib/pages/home/components/riwayat_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hpp_project/home/model/riwayat_item.dart';
import 'package:intl/intl.dart';


class RiwayatSection extends StatelessWidget {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 30),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Transaksi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildMonthLabel(),
            ],
          ),
          SizedBox(height: 16),
          _buildRiwayatContent(),
        ],
      ),
    );
  }

  Widget _buildMonthLabel() {
    final now = DateTime.now();
    final List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];
    final String monthYear = '${monthNames[now.month - 1]} ${now.year}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF080C67).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        monthYear,
        style: TextStyle(
          color: Color(0xFF080C67),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRiwayatContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(auth.currentUser?.uid)
          .collection("Pembelian")
          .orderBy('Tanggal', descending: true)
          .snapshots(),
      builder: (context, pembelianSnapshot) {
        if (pembelianSnapshot.hasError) {
          return _buildErrorState('Terjadi kesalahan saat memuat data');
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(auth.currentUser?.uid)
              .collection("Barang")
              .orderBy('Tanggal', descending: true)
              .snapshots(),
          builder: (context, barangSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(auth.currentUser?.uid)
                  .collection("Penjualan")
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, penjualanSnapshot) {
                if (pembelianSnapshot.connectionState == ConnectionState.waiting ||
                    barangSnapshot.connectionState == ConnectionState.waiting ||
                    penjualanSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (barangSnapshot.hasError || penjualanSnapshot.hasError) {
                  return _buildErrorState('Terjadi kesalahan saat memuat data');
                }

                List<RiwayatItem> riwayatItems = _processRiwayatItems(
                  barangSnapshot.data?.docs ?? [],
                  pembelianSnapshot.data?.docs ?? [],
                  penjualanSnapshot.data?.docs ?? [],
                );

                if (riwayatItems.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildRiwayatList(riwayatItems, pembelianSnapshot.data?.docs ?? [], barangSnapshot.data?.docs ?? []);
              },
            );
          },
        );
      },
    );
  }

  List<RiwayatItem> _processRiwayatItems(
    List<QueryDocumentSnapshot> barangDocs,
    List<QueryDocumentSnapshot> pembelianDocs,
    List<QueryDocumentSnapshot> penjualanDocs,
  ) {
    List<RiwayatItem> items = [];

    // Process Persediaan Awal items
    for (var doc in barangDocs) {
      final data = doc.data() as Map<String, dynamic>;
      items.add(RiwayatItem(
        title: data["Name"] ?? "Unknown",
        description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])}",
        price: (data["Jumlah"] as int) * (data["Price"] as int),
        type: "Persediaan Awal",
        date: data["Tanggal"] ?? "",
      ));
    }

    // Process Pembelian items
    for (var doc in pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      items.add(RiwayatItem(
        title: data["Name"] ?? "Unknown",
        description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])}",
        price: (data["Jumlah"] as int) * (data["Price"] as int),
        type: "Pembelian",
        date: data["Tanggal"] ?? "",
      ));
    }

    // Process Penjualan items
    for (var doc in penjualanDocs) {
      final data = doc.data() as Map<String, dynamic>;
      items.add(RiwayatItem(
        title: data["namaBarang"] ?? "Unknown",
        description: "${data["jumlah"]} ${data["satuan"]} - Rp ${NumberFormat('#,###').format(data["hargaJual"])}",
        price: data["total"] ?? 0,
        type: "Penjualan",
        date: data["tanggal"] ?? "",
      ));
    }

    // Sort all items by date
    items.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    return items;
  }

  Widget _buildRiwayatList(
    List<RiwayatItem> items,
    List<QueryDocumentSnapshot> pembelianDocs,
    List<QueryDocumentSnapshot> barangDocs,
  ) {
    return Column(
      children: [
        Container(
          height: 300,
          child: ListView.builder(
            itemCount: items.length,
            padding: EdgeInsets.only(top: 8),
            itemBuilder: (context, index) {
              return items[index];
            },
          ),
        ),
        Divider(height: 32, thickness: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Biaya:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Rp ${NumberFormat('#,###').format(_calculateTotalBiaya(pembelianDocs, barangDocs))}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF080C67),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF080C67),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.grey[400],
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada riwayat transaksi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalBiaya(List<QueryDocumentSnapshot> pembelianDocs, List<QueryDocumentSnapshot> barangDocs) {
    int total = 0;
    
    // Calculate total from Pembelian
    for (var doc in pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["Jumlah"] as int) * (data["Price"] as int);
    }
    
    // Calculate total from Persediaan Awal
    for (var doc in barangDocs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["Jumlah"] as int) * (data["Price"] as int);
    }
    
    return total;
  }
}
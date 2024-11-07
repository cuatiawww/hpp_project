// lib/pages/home/components/laporan_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hpp_project/report_persediaan_page.dart';

class LaporanSection extends StatelessWidget {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Container();

    // Get current month date range
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Format bulan dalam Bahasa Indonesia
    final List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];
    final String monthYear = '${monthNames[now.month - 1]} ${now.year}';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
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
                'Laporan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
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
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTransactionStreams(userId, startDateStr, endDateStr),
        ],
      ),
    );
  }

  Widget _buildTransactionStreams(String userId, String startDateStr, String endDateStr) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection("Penjualan")
          .where('tanggal', isGreaterThanOrEqualTo: startDateStr)
          .where('tanggal', isLessThanOrEqualTo: endDateStr)
          .snapshots(),
      builder: (context, penjualanSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .collection("Pembelian")
              .where('Tanggal', isGreaterThanOrEqualTo: startDateStr)
              .where('Tanggal', isLessThanOrEqualTo: endDateStr)
              .snapshots(),
          builder: (context, pembelianSnapshot) {
            double totalPenjualan = 0;
            double totalPembelian = 0;

            if (penjualanSnapshot.hasData) {
              for (var doc in penjualanSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalPenjualan += (data['total'] ?? 0).toDouble();
              }
            }

            if (pembelianSnapshot.hasData) {
              for (var doc in pembelianSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalPembelian += ((data['Jumlah'] ?? 0) * (data['Price'] ?? 0)).toDouble();
              }
            }

            return Column(
              children: [
                _buildTransactionCard(
                  "Penjualan",
                  totalPenjualan,
                  Icons.arrow_circle_down,
                  Colors.green.shade100,
                  Colors.green,
                  true,
                ),
                SizedBox(height: 12),
                _buildTransactionCard(
                  "Pembelian",
                  totalPembelian,
                  Icons.arrow_circle_up,
                  Colors.red.shade100,
                  Colors.red,
                  false,
                ),
                SizedBox(height: 16),
                _buildReportButton(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(
    String title,
    double amount,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
    bool isIncome,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => ReportPersediaanPage()),
        icon: Icon(Icons.document_scanner, size: 18),
        label: Text(
          'Report Persediaan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF080C67),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
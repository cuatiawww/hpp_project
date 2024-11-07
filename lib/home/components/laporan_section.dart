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

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];
    final String monthYear = '${monthNames[now.month - 1]} ${now.year}';

    return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Laporan\nKeuangan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF080C67),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFEEF2FF),  // Warna background soft
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF080C67),
                  ),
                  SizedBox(width: 6),
                  Text(
                    monthYear,
                    style: TextStyle(
                      color: Color(0xFF080C67),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTransactionCard(
                        "Penjualan",
                        totalPenjualan,
                        Icons.trending_up_rounded,
                        LinearGradient(
                          colors: [
                            Color(0xFF00B07D),
                            Color(0xFF00CA8E),
                          ],
                        ),
                        Colors.white,
                        true,
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      _buildTransactionCard(
                        "Pembelian",
                        totalPembelian,
                        Icons.trending_down_rounded,
                        LinearGradient(
                          colors: [
                            Color(0xFFFF6B6B),
                            Color(0xFFFF8E8E),
                          ],
                        ),
                        Colors.white,
                        false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
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
    Gradient gradient,
    Color iconColor,
    bool isIncome,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isIncome ? Color(0xFF00B07D).withOpacity(0.2) : Color(0xFFFF6B6B).withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
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
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Color(0xFF00B07D) : Color(0xFFFF6B6B),
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
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF080C67),
            Color(0xFF1E23A7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF080C67).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => ReportPersediaanPage()),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Lihat Report Persediaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
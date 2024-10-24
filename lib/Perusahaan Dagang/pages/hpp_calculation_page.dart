import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpp_project/service/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
class HPPCalculationPage extends StatefulWidget {
  @override
  _HPPCalculationPageState createState() => _HPPCalculationPageState();
}

class _HPPCalculationPageState extends State<HPPCalculationPage> {
  Map<String, dynamic> hppData = {};

  @override
  void initState() {
    super.initState();
    calculateHPP();
  }

  Future<void> calculateHPP() async {
    try {
      // Fetch persediaan awal
      QuerySnapshot persAwalSnapshot = await FirebaseFirestore.instance.collection("Barang").get();
      double totalPersAwal = 0;
      for (var doc in persAwalSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalPersAwal += (data['Jumlah'] as int) * (data['Price'] as int);
      }

      // Fetch pembelian
      QuerySnapshot pembelianSnapshot = await FirebaseFirestore.instance.collection("Pembelian").get();
      double totalPembelian = 0;
      for (var doc in pembelianSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalPembelian += (data['Jumlah'] as int) * (data['Price'] as int);
      }

      // Calculate barang tersedia untuk dijual
      double barangTersedia = totalPersAwal + totalPembelian;

      // Fetch persediaan akhir (assuming it's the current state in the "Barang" collection)
      QuerySnapshot persAkhirSnapshot = await FirebaseFirestore.instance.collection("Barang").get();
      double totalPersAkhir = 0;
      for (var doc in persAkhirSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalPersAkhir += (data['Jumlah'] as int) * (data['Price'] as int);
      }

      // Calculate HPP
      double hpp = barangTersedia - totalPersAkhir;

      setState(() {
        hppData = {
          'persediaanAwal': totalPersAwal,
          'pembelian': totalPembelian,
          'barangTersedia': barangTersedia,
          'persediaanAkhir': totalPersAkhir,
          'hpp': hpp,
        };
      });
    } catch (e) {
      print('Error dalam menghitung HPP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghitung HPP: $e')),
      );
    }
  }

  Future<void> generateAndPrintPDF() async {
    try {
      print('Fungsi generateAndPrintPDF dipanggil');
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Laporan Perhitungan HPP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                _buildPDFReportSection('Persediaan Awal', hppData['persediaanAwal']),
                _buildPDFReportSection('Pembelian', hppData['pembelian']),
                _buildPDFReportSection('Barang Tersedia untuk Dijual', hppData['barangTersedia']),
                _buildPDFReportSection('Persediaan Akhir', hppData['persediaanAkhir']),
                pw.Divider(thickness: 2),
                _buildPDFReportSection('Harga Pokok Penjualan (HPP)', hppData['hpp'], isTotal: true),
                pw.SizedBox(height: 20),
                pw.Text('Tanggal Cetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      print('PDF berhasil dibuat dan dikirim ke printer');
    } catch (e) {
      print('Error saat mencetak PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak PDF: $e')),
      );
    }
  }

  pw.Widget _buildPDFReportSection(String title, double? value, {bool isTotal = false}) {
    final formatter = NumberFormat("#,##0.00", "id_ID");
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value != null ? 'Rp ${formatter.format(value)}' : 'Calculating...',
            style: pw.TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perhitungan HPP'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: hppData.isNotEmpty ? generateAndPrintPDF : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Perhitungan HPP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildReportSection('Persediaan Awal', hppData['persediaanAwal']),
            _buildReportSection('Pembelian', hppData['pembelian']),
            _buildReportSection('Barang Tersedia untuk Dijual', hppData['barangTersedia']),
            _buildReportSection('Persediaan Akhir', hppData['persediaanAkhir']),
            Divider(thickness: 2),
            _buildReportSection('Harga Pokok Penjualan (HPP)', hppData['hpp'], isTotal: true),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: hppData.isNotEmpty ? generateAndPrintPDF : null,
              icon: Icon(Icons.print),
              label: Text('Cetak Laporan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, double? value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            value != null ? 'Rp ${value.toStringAsFixed(2)}' : 'Calculating...',
            style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

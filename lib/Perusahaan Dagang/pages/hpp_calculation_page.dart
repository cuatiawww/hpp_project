import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpp_project/service/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class HPPCalculationPage extends StatefulWidget {
  const HPPCalculationPage({super.key});

  @override
  _HPPCalculationPageState createState() => _HPPCalculationPageState();
}

class _HPPCalculationPageState extends State<HPPCalculationPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic> _hppData = {};
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final List<String> _months = [];
  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _calculateHPP();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  String _getMonthRangeText() {
    final startDate = DateTime.parse('$_selectedMonth-01');
    final endDate = DateTime(startDate.year, startDate.month + 1, 0);
    return '${DateFormat('d MMMM').format(startDate)} - ${DateFormat('d MMMM yyyy').format(endDate)}';
  }

  Future<void> _calculateHPP() async {
    setState(() => _isLoading = true);

    try {
      // Get date range for selected month
      final startDate = '$_selectedMonth-01';
      final endDateTemp = DateTime.parse(startDate).add(const Duration(days: 32));
      final endDate = DateFormat('yyyy-MM-dd').format(DateTime(endDateTemp.year, endDateTemp.month, 0));

      // Calculate Persediaan Awal
      final persAwalSnapshot = await _db.collection("Barang")
          .where('Tanggal', isLessThan: startDate)
          .get();
      
      double totalPersAwal = 0;
      for (var doc in persAwalSnapshot.docs) {
        var data = doc.data();
        if (data['Jumlah'] != null && data['Price'] != null) {
          totalPersAwal += (data['Jumlah'] as int) * (data['Price'] as int);
        }
      }

      // Calculate Pembelian
      final pembelianSnapshot = await _db.collection("Pembelian")
          .where('Tanggal', isGreaterThanOrEqualTo: startDate)
          .where('Tanggal', isLessThanOrEqualTo: endDate)
          .get();
      
      double totalPembelian = 0;
      for (var doc in pembelianSnapshot.docs) {
        var data = doc.data();
        if (data['Jumlah'] != null && data['Price'] != null) {
          totalPembelian += (data['Jumlah'] as int) * (data['Price'] as int);
        }
      }

      // Calculate Barang Tersedia untuk Dijual
      final barangTersedia = totalPersAwal + totalPembelian;

      // Calculate Persediaan Akhir
      final persAkhirSnapshot = await _db.collection("Barang")
          .where('Tanggal', isLessThanOrEqualTo: endDate)
          .orderBy('Tanggal', descending: true)
          .get();
      
      double totalPersAkhir = 0;
      for (var doc in persAkhirSnapshot.docs) {
        var data = doc.data();
        if (data['Jumlah'] != null && data['Price'] != null) {
          totalPersAkhir += (data['Jumlah'] as int) * (data['Price'] as int);
        }
      }

      setState(() {
        _hppData = {
          'startDate': startDate,
          'endDate': endDate,
          'persediaanAwal': totalPersAwal,
          'pembelian': totalPembelian,
          'barangTersedia': barangTersedia,
          'persediaanAkhir': totalPersAkhir,
          'hpp': barangTersedia - totalPersAkhir,
        };
        _isLoading = false;
      });

    } catch (e) {
      print('Error calculating HPP: $e');
      setState(() => _isLoading = false);
      _showError('Error menghitung HPP: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCalculationRow(String label, double value, {bool isSubtotal = false, bool isTotal = false}) {
    final textStyle = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Theme.of(context).primaryColor : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label, 
              style: textStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currencyFormat.format(value),
              style: textStyle,
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Laporan Perhitungan HPP',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Periode: ${DateFormat('MMMM yyyy').format(DateTime.parse('${_hppData['startDate']}'))}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Tanggal: ${DateFormat('d MMMM').format(DateTime.parse(_hppData['startDate']))} - ${DateFormat('d MMMM yyyy').format(DateTime.parse(_hppData['endDate']))}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                _buildPDFTable(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Dicetak pada: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
      );
    } catch (e) {
      _showError('Gagal mencetak PDF: $e');
    }
  }

  pw.Widget _buildPDFTable() {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Keterangan',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Jumlah',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        _buildPDFTableRow('Persediaan Awal', _hppData['persediaanAwal']),
        _buildPDFTableRow('Pembelian', _hppData['pembelian']),
        _buildPDFTableRow('Barang Tersedia untuk Dijual', _hppData['barangTersedia'], isSubtotal: true),
        _buildPDFTableRow('Persediaan Akhir', _hppData['persediaanAkhir']),
        _buildPDFTableRow('Harga Pokok Penjualan (HPP)', _hppData['hpp'], isTotal: true),
      ],
    );
  }

  pw.TableRow _buildPDFTableRow(String title, double value, {bool isSubtotal = false, bool isTotal = false}) {
    final style = isTotal
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle();
    final bgColor = isSubtotal
        ? PdfColors.grey100
        : isTotal
            ? PdfColors.grey200
            : PdfColors.white;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            _currencyFormat.format(value),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perhitungan HPP'),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Periode:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedMonth,
                              items: _months.map((month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(
                                      DateTime.parse('$month-01')
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                  });
                                  _calculateHPP();
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal: ${_getMonthRangeText()}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Perhitungan HPP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCalculationRow(
                              'Persediaan Awal',
                              _hppData['persediaanAwal'] ?? 0,
                            ),
                            _buildCalculationRow(
                              'Pembelian',
                              _hppData['pembelian'] ?? 0,
                            ),
                            const Divider(),
                            _buildCalculationRow(
                              'Barang Tersedia untuk Dijual',
                              _hppData['barangTersedia'] ?? 0,
                              isSubtotal: true,
                            ),
                            _buildCalculationRow(
                              'Persediaan Akhir',
                              _hppData['persediaanAkhir'] ?? 0,
                            ),
                            const Divider(),
                            _buildCalculationRow(
                              'Harga Pokok Penjualan (HPP)',
                              _hppData['hpp'] ?? 0,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateAndPrintPDF,
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Laporan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
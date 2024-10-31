// hpp_calculation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_model.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_widgets.dart';
import 'package:hpp_project/service/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HPPCalculationPage extends StatefulWidget {
  const HPPCalculationPage({super.key});

  @override
  _HPPCalculationPageState createState() => _HPPCalculationPageState();
}

class _HPPCalculationPageState extends State<HPPCalculationPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late HPPData _hppData = HPPData.empty();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final List<String> _months = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  
  // Controllers
  final _bebanAngkutController = TextEditingController(text: '0');
  final _returPembelianController = TextEditingController(text: '0');
  final _potonganPembelianController = TextEditingController(text: '0');
  
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

Future<double> _fetchPersediaanAwal(String startDate) async {
  double total = 0;
  final endDateTemp = DateTime.parse(startDate).add(const Duration(days: 32));
  final endDate = DateFormat('yyyy-MM-dd').format(DateTime(endDateTemp.year, endDateTemp.month, 0));

  // Get all items for the selected month
  final snapshot = await _db.collection("Barang")
      .where('Tanggal', isGreaterThanOrEqualTo: startDate)
      .where('Tanggal', isLessThanOrEqualTo: endDate)
      .get();

  // Create a map to store unique items with their total values
  Map<String, Map<String, dynamic>> uniqueItems = {};

  // Process each document
  for (var doc in snapshot.docs) {
    var data = doc.data();
    String key = '${data['Name']}_${data['Tipe']}';
    
    // Only store the first occurrence of each unique item
    if (!uniqueItems.containsKey(key)) {
      uniqueItems[key] = {
        'Jumlah': data['Jumlah'] ?? 0,
        'Price': data['Price'] ?? 0,
      };
    }
  }

  // Calculate total for all unique items
  uniqueItems.forEach((key, value) {
    total += (value['Jumlah'] as int) * (value['Price'] as int);
  });

  print('Persediaan Awal: $total'); // For debugging
  return total;
}
  Future<double> _fetchPembelian(String startDate, String endDate) async {
    double total = 0;
    final snapshot = await _db.collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .get();

    for (var doc in snapshot.docs) {
      var data = doc.data();
      int jumlah = data['Jumlah'] ?? 0;
      int price = data['Price'] ?? 0;
      total += jumlah * price;
    }
    return total;
  }

Future<double> _fetchPersediaanAkhir(String endDate) async {
  try {
    // Get the current month's data
    final startMonth = DateFormat('yyyy-MM').format(DateTime.parse(endDate));
    final startDate = '$startMonth-01';

    final snapshot = await _db.collection("Barang")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .get();

    double total = 0;

    // Group items by name and type to get latest entry for each
    Map<String, Map<String, dynamic>> latestItems = {};
    
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Tipe']}';
      
      // Always take the data as it's already for the current month
      latestItems[key] = {
        'Name': data['Name'],
        'Tipe': data['Tipe'],
        'Jumlah': data['Jumlah'] ?? 0,
        'Price': data['Price'] ?? 0,
        'Tanggal': data['Tanggal'],
      };
    }

    // Calculate total from the latest entries
    latestItems.forEach((key, item) {
      int jumlah = item['Jumlah'] as int;
      int price = item['Price'] as int;
      double itemTotal = jumlah * price.toDouble();
      total += itemTotal;
      
      // Debug print
      print('Persediaan Akhir Item: ${item['Name']}, Jumlah: $jumlah, Price: $price, Total: $itemTotal');
    });

    print('Total Persediaan Akhir: $total');
    return total;
  } catch (e) {
    print('Error in _fetchPersediaanAkhir: $e');
    return 0;
  }
}

Future<void> _calculateHPP() async {
  setState(() => _isLoading = true);

  try {
    final startDate = '$_selectedMonth-01';
    final endDate = DateTime(DateTime.parse(startDate).year, DateTime.parse(startDate).month + 1, 0);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Debug prints
    print('Calculating for period: $startDate to $endDateStr');

    // 1. Get Persediaan Awal
    final persediaanAwal = await _fetchPersediaanAwal(startDate);
    print('Persediaan Awal: $persediaanAwal');

    // 2. Get Pembelian
    final pembelian = await _fetchPembelian(startDate, endDateStr);
    print('Pembelian: $pembelian');

    // 3. Get additional costs
    final bebanAngkut = double.tryParse(_bebanAngkutController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final returPembelian = double.tryParse(_returPembelianController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final potonganPembelian = double.tryParse(_potonganPembelianController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // 4. Calculate Pembelian Bersih
    final pembelianBersih = pembelian + bebanAngkut - returPembelian - potonganPembelian;
    print('Pembelian Bersih: $pembelianBersih');

    // 5. Calculate Barang Tersedia
    final barangTersedia = persediaanAwal + pembelianBersih;
    print('Barang Tersedia: $barangTersedia');

    // 6. Get Persediaan Akhir (current month's total)
    final persediaanAkhir = await _fetchPersediaanAkhir(endDateStr);
    print('Persediaan Akhir: $persediaanAkhir');

    // 7. Calculate HPP
    final hpp = barangTersedia - persediaanAkhir;
    print('HPP: $hpp');

    setState(() {
      _hppData = HPPData(
        startDate: startDate,
        endDate: endDateStr,
        persediaanAwal: persediaanAwal,
        pembelian: pembelian,
        bebanAngkut: bebanAngkut,
        returPembelian: returPembelian,
        potonganPembelian: potonganPembelian,
        pembelianBersih: pembelianBersih,
        barangTersedia: barangTersedia,
        persediaanAkhir: persediaanAkhir,
        hpp: hpp,
      );
      _isLoading = false;
    });

  } catch (e) {
    print('Error calculating HPP: $e');
    setState(() => _isLoading = false);
    _showError('Error menghitung HPP: $e');
  }
}
  
  Widget _buildPeriodSelection() {
    return Card(
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
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixText: 'Rp ',
              hintText: '0',
            ),
            onChanged: (value) {
              if (_debounceTimer?.isActive ?? false) {
                _debounceTimer!.cancel();
              }
              _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  _calculateHPP();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCosts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Biaya Tambahan:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              'Beban Angkut Pembelian',
              _bebanAngkutController,
            ),
            _buildInputField(
              'Retur Pembelian',
              _returPembelianController,
            ),
            _buildInputField(
              'Potongan Pembelian',
              _potonganPembelianController,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateHPP,
                icon: const Icon(Icons.calculate),
                label: const Text('Hitung HPP'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHPPResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: HPPCalculationWidget(
          hppData: _hppData,
          currencyFormat: _currencyFormat,
        ),
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
                  'Periode: ${DateFormat('MMMM yyyy').format(DateTime.parse(_hppData.startDate))}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Tanggal: ${DateFormat('d MMMM').format(DateTime.parse(_hppData.startDate))} - ${DateFormat('d MMMM yyyy').format(DateTime.parse(_hppData.endDate))}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                _buildPDFContent(),
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

  pw.Widget _buildPDFContent() {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildPDFHeader(),
        _buildPDFRow('1. Persediaan Barang Dagang (awal)', _hppData.persediaanAwal),
        _buildPDFRow('2. Pembelian', _hppData.pembelian),
        _buildPDFRow('3. Beban Angkut Pembelian', _hppData.bebanAngkut),
        _buildPDFRow('4. Retur Pembelian', _hppData.returPembelian, isNegative: true),
        _buildPDFRow('5. Potongan Pembelian', _hppData.potonganPembelian, isNegative: true),
        _buildPDFRow('6. Pembelian Bersih', _hppData.pembelianBersih, isSubtotal: true),
        _buildPDFRow('   Barang Tersedia untuk Dijual', _hppData.barangTersedia, isSubtotal: true),
        _buildPDFRow('7. Persediaan Barang Dagang Akhir', _hppData.persediaanAkhir, isNegative: true),
        _buildPDFRow('8. Harga Pokok Penjualan', _hppData.hpp, isTotal: true),
      ],
    );
  }

  pw.TableRow _buildPDFHeader() {
    return pw.TableRow(
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
    );
  }

  pw.TableRow _buildPDFRow(String title, double value, {
    bool isSubtotal = false,
    bool isTotal = false,
    bool isNegative = false,
  }) {
    final style = isTotal ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle();
    final bgColor = isSubtotal ? PdfColors.grey100 : isTotal ? PdfColors.grey200 : PdfColors.white;

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
            isNegative ? '-${_currencyFormat.format(value)}' : _currencyFormat.format(value),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPeriodSelection(),
                  const SizedBox(height: 16),
                  _buildAdditionalCosts(),
                  const SizedBox(height: 16),
                  _buildHPPResult(),
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
    );
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _bebanAngkutController.dispose();
    _returPembelianController.dispose();
    _potonganPembelianController.dispose();
    super.dispose();
  }
}

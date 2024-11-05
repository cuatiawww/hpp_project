import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPersediaanPage extends StatefulWidget {
  const ReportPersediaanPage({Key? key}) : super(key: key);

  @override
  State<ReportPersediaanPage> createState() => _ReportPersediaanPageState();
}

class _ReportPersediaanPageState extends State<ReportPersediaanPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final List<String> _months = [];
  bool _isLoading = false;
  
  // Data holders for preview
  Map<String, Map<String, dynamic>> persAwalData = {};
  Map<String, Map<String, dynamic>> pembelianData = {};
  Map<String, Map<String, dynamic>> penjualanData = {};
  Map<String, Map<String, dynamic>> persAkhirData = {};

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _fetchData();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final startDate = '$_selectedMonth-01';
      final date = DateTime.parse(startDate);
      final endDate = DateTime(date.year, date.month + 1, 0);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      persAwalData = await _fetchPersediaanAwal(startDate);
      pembelianData = await _fetchPembelian(startDate, endDateStr);
      penjualanData = await _fetchPenjualan(startDate, endDateStr);
      persAkhirData = await _calculatePersediaanAkhir(
        persAwalData,
        pembelianData,
        penjualanData,
      );

      setState(() {});
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePDF() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Center(
                  child: pw.Text(
                    'Laporan Persediaan',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Periode: ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPDFTable(),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdf.save(),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // PDF Table Building
  pw.Widget _buildPDFTable() {
    Set<String> allItems = {
      ...persAwalData.keys,
      ...pembelianData.keys,
      ...penjualanData.keys,
      ...persAkhirData.keys,
    };

    return pw.Table(
      border: pw.TableBorder.all(),
      tableWidth: pw.TableWidth.min,
      children: [
        // Header Row 1
        pw.TableRow(
          children: [
            _buildPDFHeaderCell('No', rowSpan: 2),
            _buildPDFHeaderCell('Nama\nBarang', rowSpan: 2),
            _buildPDFHeaderCell('P.Awal', colSpan: 3),
            _buildPDFHeaderCell('Pembelian', colSpan: 3),
            _buildPDFHeaderCell('Penjualan', colSpan: 3),
            _buildPDFHeaderCell('Persediaan\nAkhir', colSpan: 3),
          ],
        ),
        // Header Row 2
        pw.TableRow(
          children: [
            pw.Container(), // No (handled by rowSpan)
            pw.Container(), // Nama Barang (handled by rowSpan)
            _buildPDFHeaderCell('Unit'),
            _buildPDFHeaderCell('Harga'),
            _buildPDFHeaderCell('Total'),
            _buildPDFHeaderCell('Unit'),
            _buildPDFHeaderCell('Harga'),
            _buildPDFHeaderCell('Total'),
            _buildPDFHeaderCell('Unit'),
            _buildPDFHeaderCell('Harga'),
            _buildPDFHeaderCell('Total'),
            _buildPDFHeaderCell('Unit'),
            _buildPDFHeaderCell('Harga'),
            _buildPDFHeaderCell('Total'),
          ],
        ),
        // Data Rows
        ...allItems.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final itemKey = entry.value;
          final persAwal = persAwalData[itemKey] ?? {};
          final pembelian = pembelianData[itemKey] ?? {};
          final penjualan = penjualanData[itemKey] ?? {};
          final persAkhir = persAkhirData[itemKey] ?? {};

          return pw.TableRow(
            children: [
              _buildPDFCell('${index + 1}'),
              _buildPDFCell(persAwal['name'] ?? pembelian['name'] ?? ''),
              _buildPDFCell(persAwal['jumlah']?.toString() ?? '0'),
              _buildPDFCell(_formatCurrency(persAwal['price'] ?? 0)),
              _buildPDFCell(_formatCurrency((persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0))),
              _buildPDFCell(pembelian['jumlah']?.toString() ?? '0'),
              _buildPDFCell(_formatCurrency(pembelian['price'] ?? 0)),
              _buildPDFCell(_formatCurrency((pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0))),
              _buildPDFCell(penjualan['jumlah']?.toString() ?? '0'),
              _buildPDFCell(_formatCurrency(penjualan['price'] ?? 0)),
              _buildPDFCell(_formatCurrency((penjualan['jumlah'] ?? 0) * (penjualan['price'] ?? 0))),
              _buildPDFCell(persAkhir['jumlah']?.toString() ?? '0'),
              _buildPDFCell(_formatCurrency(persAkhir['price'] ?? 0)),
              _buildPDFCell(_formatCurrency((persAkhir['jumlah'] ?? 0) * (persAkhir['price'] ?? 0))),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildPDFHeaderCell(String text, {int colSpan = 1, int rowSpan = 1}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildPDFCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // Preview Table Building
  Widget _buildPreviewTable() {
    Set<String> allItems = {
      ...persAwalData.keys,
      ...pembelianData.keys,
      ...penjualanData.keys,
      ...persAkhirData.keys,
    };

    return Card(
      child: Table(
        border: TableBorder.all(),
        columnWidths: const {
          0: FixedColumnWidth(40),    // No
          1: FixedColumnWidth(150),   // Nama Barang
          2: FixedColumnWidth(70),    // Unit
          3: FixedColumnWidth(100),   // Harga
          4: FixedColumnWidth(100),   // Total
          5: FixedColumnWidth(70),    // Unit
          6: FixedColumnWidth(100),   // Harga
          7: FixedColumnWidth(100),   // Total
          8: FixedColumnWidth(70),    // Unit
          9: FixedColumnWidth(100),   // Harga
          10: FixedColumnWidth(100),  // Total
          11: FixedColumnWidth(70),   // Unit
          12: FixedColumnWidth(100),  // Harga
          13: FixedColumnWidth(100),  // Total
        },
        children: [
          TableRow(
  decoration: BoxDecoration(color: Colors.grey[200]),
  children: [
    _buildPreviewHeaderCell('No'),
    _buildPreviewHeaderCell('Nama\nBarang'),
    _buildPreviewHeaderCell('P.Awal'),
    _buildPreviewHeaderCell(''),  // Empty cell for P.Awal span
    _buildPreviewHeaderCell(''),  // Empty cell for P.Awal span
    _buildPreviewHeaderCell('Pembelian'),
    _buildPreviewHeaderCell(''),  // Empty cell for Pembelian span
    _buildPreviewHeaderCell(''),  // Empty cell for Pembelian span
    _buildPreviewHeaderCell('Penjualan'),
    _buildPreviewHeaderCell(''),  // Empty cell for Penjualan span
    _buildPreviewHeaderCell(''),  // Empty cell for Penjualan span
    _buildPreviewHeaderCell('Persediaan\nAkhir'),
    _buildPreviewHeaderCell(''),  // Empty cell for Persediaan Akhir span
    _buildPreviewHeaderCell(''),  // Empty cell for Persediaan Akhir span
  ],
),
          TableRow(
  decoration: BoxDecoration(color: Colors.grey[200]),
  children: [
    _buildPreviewHeaderCell(''),  // Empty for No
    _buildPreviewHeaderCell(''),  // Empty for Nama Barang
    _buildPreviewHeaderCell('Unit'),
    _buildPreviewHeaderCell('Harga'),
    _buildPreviewHeaderCell('Total'),
    _buildPreviewHeaderCell('Unit'),
    _buildPreviewHeaderCell('Harga'),
    _buildPreviewHeaderCell('Total'),
    _buildPreviewHeaderCell('Unit'),
    _buildPreviewHeaderCell('Harga'),
    _buildPreviewHeaderCell('Total'),
    _buildPreviewHeaderCell('Unit'),
    _buildPreviewHeaderCell('Harga'),
    _buildPreviewHeaderCell('Total'),
  ],
),
          ...allItems.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final itemKey = entry.value;
            final persAwal = persAwalData[itemKey] ?? {};
            final pembelian = pembelianData[itemKey] ?? {};
            final penjualan = penjualanData[itemKey] ?? {};
            final persAkhir = persAkhirData[itemKey] ?? {};

            return TableRow(
              children: [
                _buildPreviewCell('${index + 1}'),
                _buildPreviewCell(persAwal['name'] ?? pembelian['name'] ?? ''),
                _buildPreviewCell(persAwal['jumlah']?.toString() ?? '0'),
                _buildPreviewCell(_formatCurrency(persAwal['price'] ?? 0)),
                _buildPreviewCell(_formatCurrency((persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0))),
                _buildPreviewCell(pembelian['jumlah']?.toString() ?? '0'),
                _buildPreviewCell(_formatCurrency(pembelian['price'] ?? 0)),
                _buildPreviewCell(_formatCurrency((pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0))),
                _buildPreviewCell(penjualan['jumlah']?.toString() ?? '0'),
                _buildPreviewCell(_formatCurrency(penjualan['price'] ?? 0)),
                _buildPreviewCell(_formatCurrency((penjualan['jumlah'] ?? 0) * (penjualan['price'] ?? 0))),
                _buildPreviewCell(persAkhir['jumlah']?.toString() ?? '0'),
                _buildPreviewCell(_formatCurrency(persAkhir['price'] ?? 0)),
                _buildPreviewCell(_formatCurrency((persAkhir['jumlah'] ?? 0) * (persAkhir['price'] ?? 0))),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

 Widget _buildPreviewHeaderCell(String text, {int colSpan = 1, int rowSpan = 1}) {
  return TableCell(
    verticalAlignment: TableCellVerticalAlignment.middle,
    child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}

  Widget _buildPreviewCell(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  // Data fetching methods
  Future<Map<String, Map<String, dynamic>>> _fetchPersediaanAwal(String startDate) async {
    final userId = auth.currentUser?.uid;
    final snapshot = await _db
        .collection("Users").doc(userId)
        .collection("Barang")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .get();

    Map<String, Map<String, dynamic>> result = {};
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Tipe']}';
      result[key] = {
        'name': data['Name'],
        'tipe': data['Tipe'],
        'jumlah': data['Jumlah'] ?? 0,
        'price': data['Price'] ?? 0,
      };
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPembelian(String startDate, String endDate) async {
    final userId = auth.currentUser?.uid;
    final snapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, Map<String, dynamic>> result = {};
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Type']}';
      
      if (result.containsKey(key)) {
        result[key]!['jumlah'] = (result[key]!['jumlah'] as int) + (data['Jumlah'] ?? 0);
        // Use the latest price
        result[key]!['price'] = data['Price'] ?? 0;
      } else {
        result[key] = {
          'name': data['Name'],
          'tipe': data['Type'],
          'jumlah': data['Jumlah'] ?? 0,
          'price': data['Price'] ?? 0,
        };
      }
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPenjualan(String startDate, String endDate) async {
    final userId = auth.currentUser?.uid;
    final snapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, Map<String, dynamic>> result = {};
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String key = '${data['namaBarang']}_${data['tipe']}';
      
      if (result.containsKey(key)) {
        result[key]!['jumlah'] = (result[key]!['jumlah'] as int) + (data['jumlah'] ?? 0);
        // Use the latest price
        result[key]!['price'] = data['hargaJual'] ?? 0;
      } else {
        result[key] = {
          'name': data['namaBarang'],
          'tipe': data['tipe'],
          'jumlah': data['jumlah'] ?? 0,
          'price': data['hargaJual'] ?? 0,
        };
      }
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _calculatePersediaanAkhir(
    Map<String, Map<String, dynamic>> persAwalData,
    Map<String, Map<String, dynamic>> pembelianData,
    Map<String, Map<String, dynamic>> penjualanData,
  ) async {
    Map<String, Map<String, dynamic>> result = {};
    
    Set<String> allItems = {
      ...persAwalData.keys,
      ...pembelianData.keys,
      ...penjualanData.keys,
    };

    for (String key in allItems) {
      var persAwal = persAwalData[key] ?? {'jumlah': 0, 'price': 0};
      var pembelian = pembelianData[key] ?? {'jumlah': 0, 'price': 0};
      var penjualan = penjualanData[key] ?? {'jumlah': 0, 'price': 0};

      int remainingStock = (persAwal['jumlah'] ?? 0) + 
                         (pembelian['jumlah'] ?? 0) - 
                         (penjualan['jumlah'] ?? 0);

      double price = pembelian['price'] > 0 ? 
                    pembelian['price'] : 
                    persAwal['price'] ?? 0;

      if (remainingStock >= 0) {
        result[key] = {
          'name': persAwal['name'] ?? pembelian['name'] ?? penjualan['name'],
          'tipe': persAwal['tipe'] ?? pembelian['tipe'] ?? penjualan['tipe'],
          'jumlah': remainingStock,
          'price': price,
        };
      }
    }

    return result;
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
        'Report Persediaan',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white), // Ikon back putih
        onPressed: () => Navigator.of(context).pop(),
      ),
        centerTitle: true,
        backgroundColor: const Color(0xFF080C67),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Periode:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMonth,
                      items: _months.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(
                            DateFormat('MMMM yyyy').format(
                              DateTime.parse('$month-01'),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedMonth = newValue);
                          _fetchData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: _buildPreviewTable(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generatePDF,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.print),
              label: Text(_isLoading ? 'Generating...' : 'Generate PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF080C67),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
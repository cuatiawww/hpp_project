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

  //GENERATE TO PDF

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
    columnWidths: const {
      0: pw.FixedColumnWidth(40),    // No
      1: pw.FixedColumnWidth(150),   // Nama Barang
      2: pw.FixedColumnWidth(270),   // P.Awal (merged)
      3: pw.FixedColumnWidth(270),   // Pembelian (merged)
      4: pw.FixedColumnWidth(270),   // Penjualan (merged)
      5: pw.FixedColumnWidth(270),   // Persediaan Akhir (merged)
    },
    children: [
      // Header Row 1
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _buildPDFHeaderCell('No'),
          _buildPDFHeaderCell('Nama\nBarang'),
          _buildPDFHeaderCell('P.Awal'),
          _buildPDFHeaderCell('Pembelian'),
          _buildPDFHeaderCell('Penjualan'),
          _buildPDFHeaderCell('Persediaan\nAkhir'),
        ],
      ),
      // Header Row 2
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Container(), // Empty for No
          pw.Container(), // Empty for Nama Barang
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(child: _buildPDFHeaderCell('Unit')),
              pw.Expanded(child: _buildPDFHeaderCell('Harga')),
              pw.Expanded(child: _buildPDFHeaderCell('Total')),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(child: _buildPDFHeaderCell('Unit')),
              pw.Expanded(child: _buildPDFHeaderCell('Harga')),
              pw.Expanded(child: _buildPDFHeaderCell('Total')),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(child: _buildPDFHeaderCell('Unit')),
              pw.Expanded(child: _buildPDFHeaderCell('Harga')),
              pw.Expanded(child: _buildPDFHeaderCell('Total')),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(child: _buildPDFHeaderCell('Unit')),
              pw.Expanded(child: _buildPDFHeaderCell('Harga')),
              pw.Expanded(child: _buildPDFHeaderCell('Total')),
            ],
          ),
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
    _buildPDFCell(_formatNameWithType(
      persAwal['name'] ?? pembelian['name'] ?? '',
      persAwal['tipe'] ?? pembelian['tipe'] ?? ''
    )),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Expanded(child: _buildPDFCell(persAwal['jumlah']?.toString() ?? '0')),
                pw.Expanded(child: _buildPDFCell(_formatCurrency(persAwal['price'] ?? 0))),
                pw.Expanded(child: _buildPDFCell(_formatCurrency((persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0)))),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Expanded(child: _buildPDFCell(pembelian['jumlah']?.toString() ?? '0')),
                pw.Expanded(child: _buildPDFCell(_formatCurrency(pembelian['price'] ?? 0))),
                pw.Expanded(child: _buildPDFCell(_formatCurrency((pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0)))),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Expanded(child: _buildPDFCell(penjualan['jumlah']?.toString() ?? '0')),
                pw.Expanded(child: _buildPDFCell(_formatCurrency(penjualan['price'] ?? 0))),
                pw.Expanded(child: _buildPDFCell(_formatCurrency((penjualan['jumlah'] ?? 0) * (penjualan['price'] ?? 0)))),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Expanded(child: _buildPDFCell(persAkhir['jumlah']?.toString() ?? '0')),
                pw.Expanded(child: _buildPDFCell(_formatCurrency(persAkhir['price'] ?? 0))),
                pw.Expanded(child: _buildPDFCell(_formatCurrency((persAkhir['jumlah'] ?? 0) * (persAkhir['price'] ?? 0)))),
              ],
            ),
          ],
        );
      }).toList(),
    ],
  );
}

pw.Widget _buildPDFHeaderCell(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(5),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildPDFCell(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(5),
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10),
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

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        columnWidths: const {
          0: FixedColumnWidth(40),    // No
          1: FixedColumnWidth(150),   // Nama Barang
          2: FixedColumnWidth(270),   // P.Awal
          3: FixedColumnWidth(270),   // Pembelian
          4: FixedColumnWidth(270),   // Penjualan
          5: FixedColumnWidth(270),   // Persediaan Akhir
        },
        children: [
          // Header Row 1
          TableRow(
            decoration: BoxDecoration(
              color: Color(0xFF080C67),
            ),
            children: [
              _buildPreviewHeaderCell('No', isMainHeader: true),
              _buildPreviewHeaderCell('Nama\nBarang', isMainHeader: true),
              _buildPreviewHeaderCell('Persediaan Awal', isMainHeader: true),
              _buildPreviewHeaderCell('Pembelian', isMainHeader: true),
              _buildPreviewHeaderCell('Penjualan', isMainHeader: true),
              _buildPreviewHeaderCell('Persediaan Akhir', isMainHeader: true),
            ],
          ),
          // Header Row 2
          TableRow(
            decoration: BoxDecoration(
              color: Color(0xFF080C67).withOpacity(0.9),
            ),
            children: [
              Container(), // Empty for No
              Container(), // Empty for Nama Barang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildPreviewHeaderCell('Unit')),
                  Expanded(child: _buildPreviewHeaderCell('Harga')),
                  Expanded(child: _buildPreviewHeaderCell('Total')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildPreviewHeaderCell('Unit')),
                  Expanded(child: _buildPreviewHeaderCell('Harga')),
                  Expanded(child: _buildPreviewHeaderCell('Total')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildPreviewHeaderCell('Unit')),
                  Expanded(child: _buildPreviewHeaderCell('Harga')),
                  Expanded(child: _buildPreviewHeaderCell('Total')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildPreviewHeaderCell('Unit')),
                  Expanded(child: _buildPreviewHeaderCell('Harga')),
                  Expanded(child: _buildPreviewHeaderCell('Total')),
                ],
              ),
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
            final isEvenRow = index % 2 == 0;

            return TableRow(
              decoration: BoxDecoration(
                color: isEvenRow ? Colors.grey.withOpacity(0.05) : Colors.white,
              ),
              children: [
    _buildPreviewCell('${index + 1}', isEvenRow: isEvenRow),
    _buildPreviewCell(
      _formatNameWithType(
        persAwal['name'] ?? pembelian['name'] ?? '',
        persAwal['tipe'] ?? pembelian['tipe'] ?? ''
      ),
      isEvenRow: isEvenRow,
      alignment: TextAlign.left,
    ),
                _buildPreviewDataGroup(
                  unit: persAwal['jumlah']?.toString() ?? '0',
                  price: _formatCurrency(persAwal['price'] ?? 0),
                  total: _formatCurrency((persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0)),
                  isEvenRow: isEvenRow,
                ),
                _buildPreviewDataGroup(
                  unit: pembelian['jumlah']?.toString() ?? '0',
                  price: _formatCurrency(pembelian['price'] ?? 0),
                  total: _formatCurrency((pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0)),
                  isEvenRow: isEvenRow,
                ),
                _buildPreviewDataGroup(
                  unit: penjualan['jumlah']?.toString() ?? '0',
                  price: _formatCurrency(penjualan['price'] ?? 0),
                  total: _formatCurrency((penjualan['jumlah'] ?? 0) * (penjualan['price'] ?? 0)),
                  isEvenRow: isEvenRow,
                ),
                _buildPreviewDataGroup(
                  unit: persAkhir['jumlah']?.toString() ?? '0',
                  price: _formatCurrency(persAkhir['price'] ?? 0),
                  total: _formatCurrency((persAkhir['jumlah'] ?? 0) * (persAkhir['price'] ?? 0)),
                  isEvenRow: isEvenRow,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

Widget _buildPreviewHeaderCell(String text, {bool isMainHeader = false}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: isMainHeader ? 13 : 12,
      ),
    ),
  );
}

Widget _buildPreviewCell(
  String text, {
  bool isEvenRow = false,
  TextAlign alignment = TextAlign.right,
}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Text(
      text,
      textAlign: alignment,
      style: TextStyle(
        fontSize: 12,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
String _formatNameWithType(String? name, String? type) {
  if (name == null || name.isEmpty) return '';
  if (type == null || type.isEmpty) return name;
  return '$name ($type)';
}

Widget _buildPreviewDataGroup({
  required String unit,
  required String price,
  required String total,
  required bool isEvenRow,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Text(
            unit,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Text(
            price,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Text(
            total,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
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
      String key = '${data['Name']}_${data['Tipe']}';//KONDISI NAMA SAMA TIPE
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
    
    // Temporary map untuk menyimpan total nilai penjualan
    Map<String, double> totalNilaiPenjualan = {};
    
    for (var doc in snapshot.docs) {
      var data = doc.data();
      String key = '${data['namaBarang']}_${data['tipe']}';
      
      if (result.containsKey(key)) {
        // Update jumlah
        result[key]!['jumlah'] = (result[key]!['jumlah'] as int) + (data['jumlah'] ?? 0);
        
        // Update total nilai penjualan
        totalNilaiPenjualan[key] = (totalNilaiPenjualan[key] ?? 0) + 
            ((data['hargaJual'] ?? 0) * (data['jumlah'] ?? 0));
      } else {
        result[key] = {
          'name': data['namaBarang'],
          'tipe': data['tipe'],
          'jumlah': data['jumlah'] ?? 0,
          'price': data['hargaJual'] ?? 0,
        };
        
        // Inisialisasi total nilai penjualan
        totalNilaiPenjualan[key] = (data['hargaJual'] ?? 0) * (data['jumlah'] ?? 0);
      }
    }
    
    // Hitung harga rata-rata untuk setiap item
    for (var key in result.keys) {
      if (result[key]!['jumlah'] > 0) {
        // Harga rata-rata = Total nilai penjualan / Total jumlah unit
        double averagePrice = totalNilaiPenjualan[key]! / result[key]!['jumlah'];
        result[key]!['price'] = averagePrice.round(); // Bulatkan ke integer
      }
    }

    return result;
}

// Kolom penjualan akan menampilkan:

// Jumlah: Total semua unit yang terjual
// Harga: Rata-rata dari semua harga penjualan
// Total: Total nilai semua penjualan


// Kolom persediaan akhir akan menampilkan:

// Jumlah: Sisa stok setelah penjualan
// Harga: Rata-rata tertimbang dari P.Awal dan Pembelian
// Total: Harga × Jumlah akhir
 
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
      
      // Hitung rata-rata tertimbang untuk harga akhir
      double totalNilai = (persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0) +
                         (pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0);
      int totalUnit = (persAwal['jumlah'] ?? 0) + (pembelian['jumlah'] ?? 0);
      
      double weightedAvgPrice = totalUnit > 0 ? totalNilai / totalUnit : 0;

      if (remainingStock >= 0) {
        result[key] = {
          'name': persAwal['name'] ?? pembelian['name'] ?? penjualan['name'],
          'tipe': persAwal['tipe'] ?? pembelian['tipe'] ?? penjualan['tipe'],
          'jumlah': remainingStock,
          'price': weightedAvgPrice.round(), // Bulatkan ke integer
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
                  : const Icon(Icons.print, color: Colors.white),
              label: Text(_isLoading ? 'Generating...' : 'Generate PDF', style: TextStyle(color: Colors.white)),
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
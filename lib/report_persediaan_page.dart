import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/service/database.dart';
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
  late DataUsahaController dataUsahaC;
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
    dataUsahaC = Get.put(DataUsahaController(uid: DatabaseMethods().currentUserId));
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await dataUsahaC.fetchDataUsaha(DatabaseMethods().currentUserId); // Load nama usaha
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
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            children: [
              _buildPDFHeader(font, fontBold),
              pw.SizedBox(height: 20),
              _buildPDFTable(font),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
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

pw.Widget _buildPDFHeader(pw.Font font, pw.Font fontBold) {
  return pw.Center(
    child: pw.Column(
      children: [
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Laporan ',
                style: pw.TextStyle(font: fontBold, fontSize: 24),
              ),
              pw.TextSpan(
                text: 'Persediaan',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: PdfColor.fromHex('#4F46E5'),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          dataUsahaC.namaUsaha.value,
          style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Periode: ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    ),
  );
}

  // PDF Table Building
pw.Widget _buildPDFTable(pw.Font font) {
  Set<String> allItems = {
    ...persAwalData.keys,
    ...pembelianData.keys,
    ...penjualanData.keys,
    ...persAkhirData.keys,
  };

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Main Headers
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EEF2FF'),
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromHex('#080C67'), width: 1),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: _buildHeaderCell('No', font)),
              pw.Expanded(flex: 3, child: _buildHeaderCell('Nama Barang', font)),
              pw.Expanded(flex: 4, child: _buildHeaderCell('P.Awal', font)),
              pw.Expanded(flex: 4, child: _buildHeaderCell('Pembelian', font)),
              pw.Expanded(flex: 4, child: _buildHeaderCell('Penjualan', font)),
              pw.Expanded(flex: 4, child: _buildHeaderCell('Persediaan Akhir', font)),
            ],
          ),
        ),

        // Sub Headers
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EEF2FF'),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: pw.Container()),
              pw.Expanded(flex: 3, child: pw.Container()),
              ...List.generate(4, (index) => pw.Expanded(
                flex: 4,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: _buildHeaderCell('Unit', font)),
                    pw.Expanded(child: _buildHeaderCell('Harga', font)),
                    pw.Expanded(child: _buildHeaderCell('Total', font)),
                  ],
                ),
              )),
            ],
          ),
        ),

        // Data Rows
        ...allItems.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final itemKey = entry.value;
          return _buildDataRow(
            index + 1,
            itemKey,
            font,
            backgroundColor: index % 2 == 0 ? null : PdfColor.fromHex('#F8FAFC'),
          );
        }),

        // Totals Row
        _buildTotalRow(font),
      ],
    ),
  );
}

pw.Widget _buildTotalRow(pw.Font font) {
  // Hitung total untuk setiap kategori
  double totalPersAwal = 0;
  double totalPembelian = 0;
  double totalPenjualan = 0;
  double totalPersAkhir = 0;

  // Hitung total persediaan awal
  persAwalData.forEach((key, data) {
    totalPersAwal += (data['jumlah'] ?? 0) * (data['price'] ?? 0);
  });

  // Hitung total pembelian
  pembelianData.forEach((key, data) {
    totalPembelian += (data['jumlah'] ?? 0) * (data['price'] ?? 0);
  });

  // Hitung total penjualan
  penjualanData.forEach((key, data) {
    totalPenjualan += (data['jumlah'] ?? 0) * (data['price'] ?? 0);
  });

  // Hitung total persediaan akhir
  persAkhirData.forEach((key, data) {
    totalPersAkhir += (data['jumlah'] ?? 0) * (data['price'] ?? 0);
  });

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EEF2FF'),
      border: pw.Border(
        top: pw.BorderSide(color: PdfColor.fromHex('#080C67'), width: 1),
      ),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Container(),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#080C67'),
              ),
            ),
          ),
        ),
        _buildTotalSection(totalPersAwal, font),
        _buildTotalSection(totalPembelian, font),
        _buildTotalSection(totalPenjualan, font),
        _buildTotalSection(totalPersAkhir, font),
      ],
    ),
  );
}

pw.Widget _buildTotalSection(double total, pw.Font font) {
  return pw.Expanded(
    flex: 4,
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Container()),
        pw.Expanded(child: pw.Container()),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              _formatCurrency(total),
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#080C67'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildDataRow(
  int index,
  String itemKey,
  pw.Font font, {
  PdfColor? backgroundColor,
}) {
  final persAwal = persAwalData[itemKey] ?? {};
  final pembelian = pembelianData[itemKey] ?? {};
  final penjualan = penjualanData[itemKey] ?? {};
  final persAkhir = persAkhirData[itemKey] ?? {};

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: backgroundColor,
    ),
    child: pw.Row(
      children: [
        // No
        pw.Expanded(
          flex: 1,
          child: _buildCell(index.toString(), font, alignment: pw.TextAlign.center),
        ),
        // Nama Barang
        pw.Expanded(
          flex: 3,
          child: _buildCell(
            _formatNameWithType(
              persAwal['name'] ?? pembelian['name'] ?? '',
              persAwal['tipe'] ?? pembelian['tipe'] ?? ''
            ),
            font,
            alignment: pw.TextAlign.left,
          ),
        ),
        // Persediaan Awal
        _buildDetailSection(persAwal, font),
        // Pembelian
        _buildDetailSection(pembelian, font),
        // Penjualan
        _buildDetailSection(penjualan, font),
        // Persediaan Akhir
        _buildDetailSection(persAkhir, font),
      ],
    ),
  );
}

pw.Widget _buildDetailSection(Map<String, dynamic> data, pw.Font font) {
  final jumlah = data['jumlah'] ?? 0;
  final harga = data['price'] ?? 0;
  final total = jumlah * harga;

  return pw.Expanded(
    flex: 4,
    child: pw.Row(
      children: [
        pw.Expanded(
          child: _buildCell(jumlah.toString(), font, alignment: pw.TextAlign.right),
        ),
        pw.Expanded(
          child: _buildCell(_formatCurrency(harga), font, alignment: pw.TextAlign.right),
        ),
        pw.Expanded(
          child: _buildCell(_formatCurrency(total), font, alignment: pw.TextAlign.right),
        ),
      ],
    ),
  );
}

pw.Widget _buildCell(
  String text,
  pw.Font font, {
  pw.TextAlign alignment = pw.TextAlign.center,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 9,
      ),
      textAlign: alignment,
    ),
  );
}

pw.Widget _buildHeaderCell(String text, pw.Font font) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#080C67'),
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
    
    // Parse startDate untuk mendapatkan bulan dan tahun
    final targetDate = DateTime.parse(startDate);
    
    // 1. Pertama, ambil semua pembelian di bulan yang dipilih
    final pembelianBulanIni = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThan: DateFormat('yyyy-MM-dd')
            .format(DateTime(targetDate.year, targetDate.month + 1, 1)))
        .get();

    // Kumpulkan semua item yang dibeli bulan ini
    Set<String> itemDibeliBulanIni = {};
    for (var doc in pembelianBulanIni.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        itemDibeliBulanIni.add(key);
    }

    // 2. Ambil data barang dari collection Barang
    final snapshotBarang = await _db
        .collection("Users")
        .doc(userId)
        .collection("Barang")
        .get();

    Map<String, Map<String, dynamic>> result = {};
    
    // Proses data barang, exclude yang dibeli bulan ini
    for (var doc in snapshotBarang.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Tipe']}';
        
        // Hanya masukkan ke persediaan awal jika BUKAN pembelian bulan ini
        if (!itemDibeliBulanIni.contains(key)) {
            result[key] = {
                'name': data['Name'],
                'tipe': data['Tipe'],
                'jumlah': (data['Jumlah'] ?? 0) as int,
                'price': (data['Price'] ?? 0).toDouble(),
            };
        }
    }

    // 3. Kurangi dengan penjualan dari bulan-bulan sebelumnya
    final snapshotPenjualan = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isLessThan: startDate)
        .get();

    for (var doc in snapshotPenjualan.docs) {
        var data = doc.data();
        String key = '${data['namaBarang']}_${data['tipe']}';
        
        if (result.containsKey(key)) {
            int currentStock = (result[key]!['jumlah'] as num).toInt();
            int soldAmount = (data['jumlah'] ?? 0) as int;
            
            // Update stok
            int newStock = currentStock - soldAmount;
            result[key]!['jumlah'] = newStock < 0 ? 0 : newStock;
        }
    }

    return result;
}

// Perbaiki juga method fetching pembelian untuk konsistensi
Future<Map<String, Map<String, dynamic>>> _fetchPembelian(String startDate, String endDate) async {
    final userId = auth.currentUser?.uid;
    final snapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('Tanggal', descending: true)  // Tambahkan ordering
        .get();

    Map<String, Map<String, dynamic>> result = {};
    // Map untuk akumulasi total nilai pembelian per item
    Map<String, double> totalValues = {};
    
    for (var doc in snapshot.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        
        double price = (data['Price'] ?? 0).toDouble();
        int quantity = (data['Jumlah'] ?? 0) as int;
        
        if (result.containsKey(key)) {
            // Akumulasi jumlah
            result[key]!['jumlah'] = (result[key]!['jumlah'] as int) + quantity;
            
            // Akumulasi total nilai
            totalValues[key] = (totalValues[key] ?? 0) + (price * quantity);
        } else {
            result[key] = {
                'name': data['Name'],
                'tipe': data['Type'],
                'jumlah': quantity,
                'price': price,
            };
            totalValues[key] = price * quantity;
        }
    }
    
    // Hitung harga rata-rata tertimbang untuk setiap item
    for (var key in result.keys) {
        int totalQuantity = result[key]!['jumlah'] as int;
        if (totalQuantity > 0) {
            double avgPrice = totalValues[key]! / totalQuantity;
            result[key]!['price'] = avgPrice;
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

      // Hitung saldo akhir
      int remainingStock = (persAwal['jumlah'] ?? 0) +
                         (pembelian['jumlah'] ?? 0);
      
      // Hitung harga rata-rata tertimbang hanya jika ada stok awal atau pembelian
      double weightedAvgPrice;
      if (persAwal['jumlah'] > 0 || pembelian['jumlah'] > 0) {
          double totalNilai = (persAwal['jumlah'] ?? 0) * (persAwal['price'] ?? 0) +
                            (pembelian['jumlah'] ?? 0) * (pembelian['price'] ?? 0);
          int totalUnit = (persAwal['jumlah'] ?? 0) + (pembelian['jumlah'] ?? 0);
          weightedAvgPrice = totalUnit > 0 ? totalNilai / totalUnit : 0;
      } else {
          weightedAvgPrice = 0;
      }

      if (remainingStock >= 0) {
        result[key] = {
          'name': persAwal['name'] ?? pembelian['name'] ?? penjualan['name'],
          'tipe': persAwal['tipe'] ?? pembelian['tipe'] ?? penjualan['tipe'],
          'jumlah': remainingStock,
          'price': weightedAvgPrice.round(),
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
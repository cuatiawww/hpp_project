
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_model.dart';
import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_widgets.dart';
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
  late final DataUsahaController dataUsahaC;  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late HPPData _hppData = HPPData.empty();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final List<String> _months = [];
  bool _isLoading = false;

  
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
  dataUsahaC = Get.put(DataUsahaController(uid: DatabaseMethods().currentUserId));
  _loadInitialData();
}

Future<void> _loadInitialData() async {
  await dataUsahaC.fetchDataUsaha(DatabaseMethods().currentUserId); // Tambahkan ini
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

  

Future<Map<String, dynamic>> _calculateStockValue(String startDate, String endDate) async {
  try {
    final userId = DatabaseMethods().currentUserId;
    double persediaanAwal = 0;
    double totalPembelian = 0;
    double persediaanAkhir = 0;

    // final targetDate = DateTime.parse(startDate);
    
    print('\n=== Debug Info ===');
    print('Period Start: $startDate');
    print('Period End: $endDate');

    // 1. Ambil semua pembelian di periode ini untuk identifikasi
    final pembelianSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('Tanggal')
        .get();

    // Kumpulkan tanggal pembelian pertama untuk setiap barang
    Map<String, DateTime> firstPurchaseDates = {};
    for (var doc in pembelianSnapshot.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        DateTime purchaseDate = DateTime.parse(data['Tanggal']);
        
        if (!firstPurchaseDates.containsKey(key) || 
            purchaseDate.isBefore(firstPurchaseDates[key]!)) {
            firstPurchaseDates[key] = purchaseDate;
        }
    }

    // 2. Hitung persediaan awal
    final barangSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Barang")
        .get();

    Map<String, Map<String, dynamic>> stockAtStartOfMonth = {};

    // Proses semua barang
    for (var doc in barangSnapshot.docs) {
        var data = doc.data();
        String tanggalBarang = data['Tanggal'] ?? '';
        String key = '${data['Name']}_${data['Tipe']}';
        
        // Cek apakah ini input awal atau pembelian
        bool isPembelian = data['isFromPembelian'] ?? false;
        
        // Jika barang ini adalah input awal (bukan dari pembelian)
        // ATAU jika tanggalnya sebelum pembelian pertama barang tersebut
        if (!isPembelian || (firstPurchaseDates[key] == null || 
            tanggalBarang.compareTo(DateFormat('yyyy-MM-dd').format(firstPurchaseDates[key]!)) < 0)) {
            
            int jumlah = (data['Jumlah'] as num?)?.toInt() ?? 0;
            double harga = (data['Price'] as num?)?.toDouble() ?? 0;
            
            print('\nProcessing initial stock:');
            print('Item: $key');
            print('Date: $tanggalBarang');
            print('Quantity: $jumlah');
            print('Price: $harga');
            print('Is from purchase: $isPembelian');
            
            if (!stockAtStartOfMonth.containsKey(key)) {
                stockAtStartOfMonth[key] = {
                    'jumlah': jumlah,
                    'harga': harga,
                };
            } else {
                // Update dengan metode average
                var currentStock = stockAtStartOfMonth[key]!;
                int totalJumlah = currentStock['jumlah'] + jumlah;
                double totalNilai = (currentStock['jumlah'] * currentStock['harga']) + (jumlah * harga);
                double avgHarga = totalJumlah > 0 ? totalNilai / totalJumlah : harga;
                
                stockAtStartOfMonth[key] = {
                    'jumlah': totalJumlah,
                    'harga': avgHarga,
                };
            }
        }
    }

    // Kurangi dengan penjualan yang terjadi sebelum pembelian pertama
    final penjualanSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('tanggal')
        .get();

    for (var doc in penjualanSnapshot.docs) {
        var data = doc.data();
        String key = '${data['namaBarang']}_${data['tipe']}';
        DateTime saleDate = DateTime.parse(data['tanggal']);
        
        // Hanya kurangi jika penjualan terjadi sebelum pembelian pertama
        if (firstPurchaseDates[key] == null || 
            saleDate.isBefore(firstPurchaseDates[key]!)) {
            if (stockAtStartOfMonth.containsKey(key)) {
                int soldAmount = (data['jumlah'] ?? 0) as int;
                stockAtStartOfMonth[key]!['jumlah'] -= soldAmount;
            }
        }
    }

    // Hitung total persediaan awal
    for (var entry in stockAtStartOfMonth.entries) {
        var stock = entry.value;
        if (stock['jumlah'] > 0) {
            double nilai = stock['jumlah'] * stock['harga'];
            persediaanAwal += nilai;
            
            print('\nPersediaan Awal Detail:');
            print('Item: ${entry.key}');
            print('Quantity: ${stock['jumlah']}');
            print('Price: ${stock['harga']}');
            print('Total Value: $nilai');
        }
    }

    // 3. Hitung pembelian dalam periode
    for (var doc in pembelianSnapshot.docs) {
        var data = doc.data();
        int jumlah = (data['Jumlah'] ?? 0) as int;
        double harga = (data['Price'] ?? 0).toDouble();
        totalPembelian += jumlah * harga;
    }

    // 4. Hitung persediaan akhir
    Map<String, Map<String, dynamic>> finalStock = Map.from(stockAtStartOfMonth);

    // Tambahkan pembelian ke stok akhir
    for (var doc in pembelianSnapshot.docs) {
        var data = doc.data();
        String key = '${data['Name']}_${data['Type']}';
        int jumlah = (data['Jumlah'] ?? 0) as int;
        double harga = (data['Price'] ?? 0).toDouble();

        if (finalStock.containsKey(key)) {
            var current = finalStock[key]!;
            int newTotal = current['jumlah'] + jumlah;
            double newAvg = ((current['jumlah'] * current['harga']) + (jumlah * harga)) / newTotal;
            finalStock[key] = {'jumlah': newTotal, 'harga': newAvg};
        } else {
            finalStock[key] = {'jumlah': jumlah, 'harga': harga};
        }
    }

    // Kurangi semua penjualan dalam periode
    for (var doc in penjualanSnapshot.docs) {
        var data = doc.data();
        String key = '${data['namaBarang']}_${data['tipe']}';
        if (finalStock.containsKey(key)) {
            int soldAmount = (data['jumlah'] ?? 0) as int;
            finalStock[key]!['jumlah'] -= soldAmount;
        }
    }

    // Hitung total persediaan akhir
    for (var stock in finalStock.values) {
        if (stock['jumlah'] > 0) {
            persediaanAkhir += stock['jumlah'] * stock['harga'];
        }
    }

    print('\n=== Hasil Perhitungan ===');
    print('Persediaan Awal: $persediaanAwal');
    print('Total Pembelian: $totalPembelian');
    print('Persediaan Akhir: $persediaanAkhir');

    return {
        'persediaan_awal': persediaanAwal,
        'pembelian': totalPembelian,
        'persediaan_akhir': persediaanAkhir
    };
  } catch (e, stackTrace) {
    print('ERROR in _calculateStockValue: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _calculateHPP() async {
  setState(() => _isLoading = true);
  
  try {
    // Format tanggal
    final startDate = '$_selectedMonth-01';
    final endDate = DateTime(
      DateTime.parse(startDate).year,
      DateTime.parse(startDate).month + 1,
      0
    );
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    print('Calculating HPP for period: $startDate to $endDateStr');

    // Ambil nilai stok dan pembelian
    final stockValues = await _calculateStockValue(startDate, endDateStr);

    // Parse input biaya tambahan dengan aman
    final bebanAngkut = double.tryParse(
      _bebanAngkutController.text.replaceAll(RegExp(r'[^0-9]'), '')
    ) ?? 0.0;
    final returPembelian = double.tryParse(
      _returPembelianController.text.replaceAll(RegExp(r'[^0-9]'), '')
    ) ?? 0.0;
    final potonganPembelian = double.tryParse(
      _potonganPembelianController.text.replaceAll(RegExp(r'[^0-9]'), '')
    ) ?? 0.0;

    // Buat instance HPPData baru dengan nilai yang sudah benar
    final newHPPData = HPPData(
      startDate: startDate,
      endDate: endDateStr,
      persediaanAwal: stockValues['persediaan_awal'] ?? 0.0,
      pembelian: stockValues['pembelian'] ?? 0.0,
      bebanAngkut: bebanAngkut,
      returPembelian: returPembelian,
      potonganPembelian: potonganPembelian,
      persediaanAkhir: stockValues['persediaan_akhir'] ?? 0.0,
    );

    // Debug print untuk memeriksa nilai
    print('Persediaan Awal: ${newHPPData.persediaanAwal}');
    print('Pembelian: ${newHPPData.pembelian}');
    print('Beban Angkut: ${newHPPData.bebanAngkut}');
    print('Retur Pembelian: ${newHPPData.returPembelian}');
    print('Potongan Pembelian: ${newHPPData.potonganPembelian}');
    print('Pembelian Bersih: ${newHPPData.pembelianBersih}');
    print('Barang Tersedia: ${newHPPData.barangTersedia}');
    print('Persediaan Akhir: ${newHPPData.persediaanAkhir}');
    print('HPP: ${newHPPData.hpp}');

    // Update state
    setState(() {
      _hppData = newHPPData;
      _isLoading = false;
    });

  } catch (e, stackTrace) {
    print('Error calculating HPP: $e');
    print('Stack trace: $stackTrace');
    setState(() => _isLoading = false);
    _showError('Error menghitung HPP: $e');
  }
}
  
  
  Widget _buildPeriodSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF080C67),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Periode Perhitungan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMonth,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF080C67)),
                items: _months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(
                      DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _selectedMonth = newValue);
                    _calculateHPP();
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Rentang Tanggal: ${_getMonthRangeText()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF080C67),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.payments_rounded, color: Color(0xFF080C67), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixText: 'Rp ',
              hintText: '0',
            ),
            // Hapus onChanged event untuk menghindari auto-calculate
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalCosts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF080C67),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Biaya Tambahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildInputField('Beban Angkut Pembelian', _bebanAngkutController),
          SizedBox(height: 16),
          _buildInputField('Retur Pembelian', _returPembelianController),
          SizedBox(height: 16),
          _buildInputField('Potongan Pembelian', _potonganPembelianController),
          SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
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
                onTap: () {
                  // Tambahkan FocusScope untuk unfocus keyboard
                  FocusScope.of(context).unfocus();
                  _calculateHPP();
                },
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Hitung HPP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHPPResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assessment_rounded,
                  color: Color(0xFF080C67),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Hasil Perhitungan HPP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          HPPCalculationWidget(
            hppData: _hppData,
            currencyFormat: _currencyFormat,
          ),
        ],
      ),
    );
  }
Future<void> _generateAndPrintPDF() async {
  try {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final userId = DatabaseMethods().currentUserId;

    // Get data for start and end of month
    final startDate = _hppData.startDate;
    final endDate = _hppData.endDate;

    // Menyiapkan header image sekali saja
    final ByteData imageData = await rootBundle.load('assets/images/logo-apps.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    // Fetch data dari Firebase
    final barangSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Barang")
        .get();

    final pembelianSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .get();

    final penjualanSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    // Fungsi helper untuk membuat header
    pw.Widget buildHeader() {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Laporan HPP',
                        style: pw.TextStyle(font: fontBold, fontSize: 24),
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
                  'Dari ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.startDate))} sampai ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.endDate))}',
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: 60,
              width: 60,
              alignment: pw.Alignment.topRight,
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    }

    // Page 1 - Persediaan Awal dan Pembelian
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              pw.SizedBox(height: 20),
              _buildDetailTable(
                'Persediaan Awal',
                barangSnapshot.docs,
                font,
                (data) => data['isFromPembelian'] != true,
              ),
              pw.SizedBox(height: 20),
              _buildDetailTable(
                'Pembelian',
                pembelianSnapshot.docs,
                font,
                (data) => true,
                isPembelian: true,
              ),
            ],
          );
        },
      ),
    );

    // Page 2 - Penjualan dan Persediaan Akhir
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              pw.SizedBox(height: 20),
              _buildDetailTable(
                'Penjualan',
                penjualanSnapshot.docs,
                font,
                (data) => true,
                isPenjualan: true,
              ),
              pw.SizedBox(height: 20),
              _buildDetailTable(
                'Persediaan Akhir',
                barangSnapshot.docs,
                font,
                (data) => true,
                includeEndingStock: true,
              ),
            ],
          );
        },
      ),
    );

    // Page 3 - Ringkasan HPP
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              pw.SizedBox(height: 20),
              _buildPDFContent(),
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
    _showError('Gagal mencetak PDF: $e');
  }
}

pw.Widget _buildDetailTable(
  String title,
  List<QueryDocumentSnapshot> docs,
  pw.Font font,
  bool Function(Map<String, dynamic>) filter, {
  bool isPembelian = false,
  bool isPenjualan = false,
  bool includeEndingStock = false,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Table Header Section
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(10)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#080C67'),
            ),
          ),
        ),
        
        // Table Content
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: _buildTableContent(docs, font, filter, isPembelian, isPenjualan),
        ),
      ],
    ),
  );
}

pw.Widget _buildTableContent(
  List<QueryDocumentSnapshot> docs,
  pw.Font font,
  bool Function(Map<String, dynamic>) filter,
  bool isPembelian,
  bool isPenjualan,
) {
  final rows = <pw.TableRow>[];
  double total = 0;

  // Column Headers with improved design
  rows.add(pw.TableRow(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EEF2FF'),
      border: pw.Border(
        bottom: pw.BorderSide(
          color: PdfColor.fromHex('#080C67'),
          width: 1,
        ),
      ),
    ),
    children: [
      'Nama Barang',
      'Jenis',
      'Unit',
      'Harga',
      'Total',
    ].map((text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#080C67'),
        ),
        textAlign: text == 'Unit' || text == 'Harga' || text == 'Total' 
            ? pw.TextAlign.right 
            : pw.TextAlign.left,
      ),
    )).toList(),
  ));

  // Data Rows with alternating colors
  int index = 0;
  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (filter(data)) {
      rows.add(_buildDataRow(
        data, 
        font, 
        isPembelian, 
        isPenjualan,
        index % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#F8FAFC'),
      ));
      total += _calculateRowTotal(data, isPenjualan);
      index++;
    }
  }

  // Total Row with bold border and background
  rows.add(pw.TableRow(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EEF2FF'),
      border: pw.Border(
        top: pw.BorderSide(color: PdfColor.fromHex('#080C67'), width: 1),
      ),
    ),
    children: [
      _buildCell(
        'TOTAL',
        font,
        fontWeight: pw.FontWeight.bold,
        colspan: 4,
        color: PdfColor.fromHex('#080C67'),
        alignment: pw.TextAlign.center,
      ),
      _buildCell(
        _formatCurrency(total),
        font,
        alignment: pw.TextAlign.right,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#080C67'),
      ),
    ],
  ));

  return pw.Table(
    border: pw.TableBorder(
      left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    columnWidths: {
      0: const pw.FlexColumnWidth(3), // Nama Barang
      1: const pw.FlexColumnWidth(2), // Jenis
      2: const pw.FlexColumnWidth(1), // Unit
      3: const pw.FlexColumnWidth(2), // Harga
      4: const pw.FlexColumnWidth(2), // Total
    },
    children: rows,
  );
}



// Helper function to build data row
pw.TableRow _buildDataRow(
  Map<String, dynamic> data,
  pw.Font font,
  bool isPembelian,
  bool isPenjualan,
  PdfColor backgroundColor,
) {
  final name = isPenjualan ? data['namaBarang'] : data['Name'];
  final type = isPenjualan ? data['tipe'] : (isPembelian ? data['Type'] : data['Tipe']);
  final unit = isPenjualan ? data['jumlah'] : data['Jumlah'];
  final price = isPenjualan ? data['hargaJual'] : data['Price'];
  final total = (unit as num) * (price as num);

  return pw.TableRow(
    decoration: pw.BoxDecoration(color: backgroundColor),
    children: [
      _buildCell(name ?? '', font),
      _buildCell(type ?? '', font),
      _buildCell(
        unit.toString(), 
        font, 
        alignment: pw.TextAlign.right
      ),
      _buildCell(
        _formatCurrency(price), 
        font, 
        alignment: pw.TextAlign.right
      ),
      _buildCell(
        _formatCurrency(total), 
        font, 
        alignment: pw.TextAlign.right
      ),
    ],
  );
}
pw.Widget _buildCell(
  String text,
  pw.Font font, {
  pw.TextAlign alignment = pw.TextAlign.left,
  pw.FontWeight fontWeight = pw.FontWeight.normal,
  PdfColor? color,
  int colspan = 1,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: colspan > 1
        ? pw.Center(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: fontWeight,
                color: color ?? PdfColors.grey800,
              ),
              textAlign: alignment,
            ),
          )
        : pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: fontWeight,
              color: color ?? PdfColors.grey800,
            ),
            textAlign: alignment,
          ),
  );
}

String _formatCurrency(num value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

double _calculateRowTotal(Map<String, dynamic> data, bool isPenjualan) {
  final unit = isPenjualan ? data['jumlah'] : data['Jumlah'];
  final price = isPenjualan ? data['hargaJual'] : data['Price'];
  return (unit as num) * (price as num).toDouble();
}

pw.Widget _buildPDFContent() {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
            children: [
              _buildHeaderRowNew(),
              _buildDataRowNew('1. Persediaan Barang Dagang (awal)', _hppData.persediaanAwal),
              _buildDataRowNew('2. Pembelian', _hppData.pembelian),
              _buildDataRowNew('3. Beban Angkut Pembelian', _hppData.bebanAngkut),
              _buildDataRowNew('4. Retur Pembelian', _hppData.returPembelian, isNegative: true),
              _buildDataRowNew('5. Potongan Pembelian', _hppData.potonganPembelian, isNegative: true),
              _buildDataRowNew('6. Pembelian Bersih', _hppData.pembelianBersih, isSubtotal: true),
              _buildDataRowNew('   Barang Tersedia untuk Dijual', _hppData.barangTersedia, isSubtotal: true),
              _buildDataRowNew('7. Persediaan Barang Dagang Akhir', _hppData.persediaanAkhir, isNegative: true),
              _buildDataRowNew('8. Harga Pokok Penjualan', _hppData.hpp, isTotal: true),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.TableRow _buildHeaderRowNew() {
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EEF2FF'),
      border: pw.Border(
        bottom: pw.BorderSide(
          color: PdfColor.fromHex('#080C67'),
          width: 1,
        ),
      ),
    ),
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: pw.Text(
          'Keterangan',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#080C67'),
          ),
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: pw.Text(
          'Jumlah',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#080C67'),
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}

pw.TableRow _buildDataRowNew(
  String title, 
  double value, {
  bool isSubtotal = false,
  bool isTotal = false,
  bool isNegative = false,
}) {
  final backgroundColor = isTotal 
      ? PdfColor.fromHex('#EEF2FF')
      : isSubtotal 
          ? PdfColor.fromHex('#F8FAFC') 
          : PdfColors.white;

  final textColor = isTotal || isSubtotal
      ? PdfColor.fromHex('#080C67')
      : PdfColors.grey800;

  final fontWeight = isTotal || isSubtotal
      ? pw.FontWeight.bold
      : pw.FontWeight.normal;

  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: backgroundColor,
      border: isTotal ? pw.Border(
        top: pw.BorderSide(color: PdfColor.fromHex('#080C67'), width: 1),
      ) : null,
    ),
    children: [
      // Title Column
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
      // Value Column
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: pw.Text(
          isNegative 
              ? '-${_currencyFormat.format(value)}'
              : _currencyFormat.format(value),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: fontWeight,
            color: textColor,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}
// Future<pw.Widget> _buildPDFHeader(pw.Font font, pw.Font fontBold) async {
//   // Ubah fungsi menjadi async dan return Future
//   final ByteData imageData = await rootBundle.load('assets/images/logo-apps.png');
//   final Uint8List imageBytes = imageData.buffer.asUint8List();

//   return pw.Row(
//     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//     crossAxisAlignment: pw.CrossAxisAlignment.start, // Tambahkan ini untuk alignment vertikal
//     children: [
//       // Left side - Title and details
//       pw.Expanded(  // Tambahkan Expanded untuk mengatur ruang
//         flex: 3,   // Berikan flex lebih besar untuk sisi kiri
//         child: pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.RichText(
//               text: pw.TextSpan(
//                 children: [
//                   pw.TextSpan(
//                     text: 'Laporan HPP',
//                     style: pw.TextStyle(font: fontBold, fontSize: 24),
//                   ),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 4),
//             pw.Text(
//               dataUsahaC.namaUsaha.value,
//               style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey800),
//             ),
//             pw.SizedBox(height: 4),
//             pw.Text(
//               'Dari ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.startDate))} sampai ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.endDate))}',
//               style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
//             ),
//           ],
//         ),
//       ),
      
//       // Right side - Logo
//       pw.Expanded(  // Tambahkan Expanded untuk sisi kanan
//         flex: 1,    // Berikan flex lebih kecil untuk logo
//         child: pw.Container(
//           height: 60,
//           width: 60,
//           alignment: pw.Alignment.topRight, // Atur alignment logo ke kanan atas
//           child: pw.Image(
//             pw.MemoryImage(imageBytes),
//             fit: pw.BoxFit.contain,
//           ),
//         ),
//       ),
//     ],
//   );
// }
  
  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Perhitungan HPP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
            ),
          ),
        ),
      ),
      body: Container(
        color: Color(0xFFF8FAFC),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodSelection(),
                    SizedBox(height: 24),
                    _buildAdditionalCosts(),
                    SizedBox(height: 24),
                    _buildHPPResult(),
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
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
                          onTap: _generateAndPrintPDF,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print_rounded, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Cetak Laporan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

   void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _bebanAngkutController.dispose();
    _returPembelianController.dispose();
    _potonganPembelianController.dispose();
    super.dispose();
  }
}

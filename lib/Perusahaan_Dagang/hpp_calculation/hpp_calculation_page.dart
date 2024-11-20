import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
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

Future<Map<String, dynamic>> _calculateStockValue(String startDate, String endDate) async {
  try {
    final userId = DatabaseMethods().currentUserId;
    double persediaanAwal = 0;
    double totalPembelian = 0;
    double persediaanAkhir = 0;

    final targetDate = DateTime.parse(startDate);
    
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
    
    // Add standard font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Load the decoration image
    // final decorationImage = pw.MemoryImage(
    //   (await rootBundle.load('assets/images/watermark.png')).buffer.asUint8List(),
    // );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Stack(
            children: [
              // Decoration image at bottom right
              // pw.Positioned(
              //   bottom: 0,
              //   right: 0,
              //   child: pw.Image(decorationImage, width: 200),
              // ),
              // Main content
              pw.Column(
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Laporan ',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 24,
                                ),
                              ),
                              pw.TextSpan(
                                text: 'HPP',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 24,
                                  color: PdfColor(0.4, 0.4, 0.8, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'PT. Nama Perusahaan',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 14,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Dari ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.startDate))} sampai ${DateFormat('dd MMMM yyyy').format(DateTime.parse(_hppData.endDate))}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // Table
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),  // Deskripsi
                      1: const pw.FlexColumnWidth(2),  // Harga
                    },
                    children: [
                      // Header row
                      _buildHeaderRow(font),
                      _buildDataRow('Persediaan Barang Dagang Awal', _hppData.persediaanAwal, font),
                      _buildDataRow('Pembelian', _hppData.pembelian, font),
                      _buildDataRow('Beban Angkut Pembelian', _hppData.bebanAngkut, font),
                      _buildDataRow('Retur Pembelian', _hppData.returPembelian, font),
                      _buildDataRow('Potongan Pembelian', _hppData.potonganPembelian, font),
                      _buildDataRow('Pembelian Bersih', _hppData.pembelianBersih, font, subtotal: true),
                      _buildDataRow('Jumlah Pembelian Bersih', _hppData.barangTersedia, font, subtotal: true),
                      _buildDataRow('Barang Tersedia Untuk Dijual (BTUD)', _hppData.barangTersedia, font),
                      _buildDataRow('Persediaan Barang Dagang Akhir', _hppData.persediaanAkhir, font),
                      _buildDataRow('Harga Pokok Penjualan', _hppData.hpp, font, total: true),
                    ],
                  ),
                ],
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

// Helper function to build header row
pw.TableRow _buildHeaderRow(pw.Font font) {
  return pw.TableRow(
    children: [
      'Deskripsi',
      'Harga',
    ].map((text) => pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
    )).toList(),
  );
}

// Helper function to build data row
pw.TableRow _buildDataRow(
  String description,
  double value,
  pw.Font font, {
  bool subtotal = false,
  bool total = false,
}) {
  final backgroundColor = total
      ? PdfColor(0.4, 0.4, 0.8, 0.2)  // Light blue for total
      : subtotal
          ? PdfColor(0.95, 0.95, 1, 1)  // Very light blue for subtotal
          : null;

  return pw.TableRow(
    decoration: backgroundColor != null
        ? pw.BoxDecoration(color: backgroundColor)
        : null,
    children: [
      pw.Padding(
        padding: pw.EdgeInsets.all(8),
        child: pw.Text(
          description,
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(8),
        child: pw.Text(
          _currencyFormat.format(value),
          style: pw.TextStyle(font: font, fontSize: 10),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}

pw.Widget _buildTableCell(String text, pw.Font font, {
  bool isHeader = false,
  bool isRight = false,
  PdfColor? backgroundColor,
}) {
  return pw.Container(
    padding: pw.EdgeInsets.all(8),
    color: backgroundColor,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 10,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
    ),
  );
}
pw.TableRow _buildTableRow(
  String description,
  String unit,
  double value,
  pw.Font font, {
  bool isSubtotal = false,
  bool isTotal = false,
  String keterangan = '',
}) {
  final backgroundColor = isTotal
      ? PdfColor.fromHex('#EEF2FF')
      : isSubtotal
          ? PdfColor.fromHex('#F8FAFC')
          : null;

  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: backgroundColor,
    ),
    children: [
      _buildTableCell(description, font),
      _buildTableCell(unit, font),
      _buildTableCell(_currencyFormat.format(value), font, isRight: true),
      _buildTableCell(keterangan, font),
    ],
  );
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

// hpp_calculation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    // 1. Hitung persediaan awal dari persediaan akhir bulan sebelumnya
    final prevMonthDate = DateTime.parse(startDate).subtract(Duration(days: 1));
    final prevMonthStr = DateFormat('yyyy-MM').format(prevMonthDate);
    final prevMonthEndStr = DateFormat('yyyy-MM-dd').format(prevMonthDate);
    
    print('Getting previous month data: $prevMonthStr');

    // Pertama, ambil data barang dari bulan sebelumnya
    Map<String, Map<String, dynamic>> prevMonthStock = {};
    
    final prevBarangSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Barang")
        .where('Tanggal', isLessThanOrEqualTo: prevMonthEndStr)
        .orderBy('Tanggal', descending: true)
        .get();

    // Proses data barang
    for (var doc in prevBarangSnapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Tipe']}';
      
      if (!prevMonthStock.containsKey(key)) {
        prevMonthStock[key] = {
          'jumlah': data['Jumlah'] ?? 0,
          'price': data['Price'] ?? 0,
        };
      }
    }

    // Tambahkan pembelian bulan sebelumnya
    final prevPembelianSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: '$prevMonthStr-01')
        .where('Tanggal', isLessThanOrEqualTo: prevMonthEndStr)
        .get();

    for (var doc in prevPembelianSnapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Type']}';
      
      if (prevMonthStock.containsKey(key)) {
        var currentStock = prevMonthStock[key]!;
        int newJumlah = currentStock['jumlah'] + (data['Jumlah'] ?? 0);
        double newPrice = ((currentStock['jumlah'] * currentStock['price']) + 
                       ((data['Jumlah'] ?? 0) * (data['Price'] ?? 0))) / newJumlah;
        
        prevMonthStock[key]!['jumlah'] = newJumlah;
        prevMonthStock[key]!['price'] = newPrice;
      } else {
        prevMonthStock[key] = {
          'jumlah': data['Jumlah'] ?? 0,
          'price': data['Price'] ?? 0,
        };
      }
    }

    // Kurangi penjualan bulan sebelumnya
    final prevPenjualanSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: '$prevMonthStr-01')
        .where('tanggal', isLessThanOrEqualTo: prevMonthEndStr)
        .get();

    for (var doc in prevPenjualanSnapshot.docs) {
      var data = doc.data();
      String key = '${data['namaBarang']}_${data['tipe']}';
      
      if (prevMonthStock.containsKey(key)) {
        prevMonthStock[key]!['jumlah'] -= (data['jumlah'] ?? 0);
      }
    }

    // Sisa stok bulan sebelumnya menjadi persediaan awal bulan ini
    for (var stock in prevMonthStock.values) {
      if (stock['jumlah'] > 0) {
        persediaanAwal += stock['jumlah'] * stock['price'];
      }
    }

    print('Persediaan Awal (from prev month): $persediaanAwal');

    // 2. Hitung pembelian dalam periode ini
    final pembelianSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .where('Tanggal', isGreaterThanOrEqualTo: startDate)
        .where('Tanggal', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, Map<String, dynamic>> currentStock = Map.from(prevMonthStock);

    // Tambahkan pembelian ke stok
    for (var doc in pembelianSnapshot.docs) {
      var data = doc.data();
      String key = '${data['Name']}_${data['Type']}';
      int jumlahBeli = data['Jumlah'] ?? 0;
      double hargaBeli = (data['Price'] ?? 0).toDouble();
      
      totalPembelian += jumlahBeli * hargaBeli;

      if (currentStock.containsKey(key)) {
        var stock = currentStock[key]!;
        int newJumlah = stock['jumlah'] + jumlahBeli;
        double newPrice = ((stock['jumlah'] * stock['price']) + 
                       (jumlahBeli * hargaBeli)) / newJumlah;
        
        currentStock[key]!['jumlah'] = newJumlah;
        currentStock[key]!['price'] = newPrice;
      } else {
        currentStock[key] = {
          'jumlah': jumlahBeli,
          'price': hargaBeli,
        };
      }
    }

    // 3. Kurangi penjualan periode ini
    final penjualanSnapshot = await _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    for (var doc in penjualanSnapshot.docs) {
      var data = doc.data();
      String key = '${data['namaBarang']}_${data['tipe']}';
      
      if (currentStock.containsKey(key)) {
        currentStock[key]!['jumlah'] -= (data['jumlah'] ?? 0);
      }
    }

    // 4. Hitung persediaan akhir
    for (var stock in currentStock.values) {
      if (stock['jumlah'] > 0) {
        persediaanAkhir += stock['jumlah'] * stock['price'];
      }
    }

    print('Calculation Results:');
    print('Persediaan Awal: $persediaanAwal');
    print('Total Pembelian: $totalPembelian');
    print('Persediaan Akhir: $persediaanAkhir');

    return {
      'persediaan_awal': persediaanAwal,
      'pembelian': totalPembelian,
      'persediaan_akhir': persediaanAkhir
    };
  } catch (e) {
    print('Error in _calculateStockValue: $e');
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

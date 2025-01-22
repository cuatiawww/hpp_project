import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/input_pembelian_page.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/service/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  // Data holders
  final Map<String, Map<String, dynamic>> _barangCache = {};
  final Map<String, Map<String, dynamic>> _combinedData = {};
  List<String> _months = [];
  List<QueryDocumentSnapshot> _pembelianDocs = [];
  
  // Business data
  late DataUsahaController _dataUsahaController;
  Map<String, dynamic> _businessData = {
    'Nama Usaha': '',
    'Tipe Usaha': '',
    'Nomor Telepon': '',
  };
  
  // State variables
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  // Loading states
  bool _isLoadingBarang = true;
  bool _isLoadingPembelian = true;
  bool _isLoadingBusinessData = true;
  
  // Firebase references
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Query _pembelianQuery;

  @override
  void initState() {
    super.initState();
    _initializeControllers(); // Add this line
    _generateMonths();
    _initializeData();
  }

  void _initializeControllers() {
    final userId = DatabaseMethods().currentUserId;
    _dataUsahaController = Get.put(DataUsahaController(uid: userId));
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoadingBusinessData = true);
    try {
      await _dataUsahaController.fetchDataUsaha(_dataUsahaController.uid);
      setState(() {
        _businessData = {
          'Nama Usaha': _dataUsahaController.namaUsaha.value,
          'Tipe Usaha': _dataUsahaController.tipeUsaha.value,
          'Nomor Telepon': _dataUsahaController.nomorTelepon.value,
        };
        _isLoadingBusinessData = false;
      });
    } catch (e) {
      print('Error loading business data: $e');
      setState(() => _isLoadingBusinessData = false);
    }
  }

  void _generateMonths() {
  final now = DateTime.now();
  _months = [];
  
  // 6 bulan sebelumnya
  for (int i = 6; i >= 1; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    _months.add(DateFormat('yyyy-MM').format(month));
  }
  
  // Bulan sekarang
  _months.add(DateFormat('yyyy-MM').format(now));
  
  // 6 bulan kedepan
  for (int i = 1; i <= 6; i++) {
    final month = DateTime(now.year, now.month + i, 1);
    _months.add(DateFormat('yyyy-MM').format(month));
  }
}

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingBarang = true;
      _isLoadingPembelian = true;
    });

    final userId = DatabaseMethods().currentUserId;
    _pembelianQuery = _db
        .collection('Users')
        .doc(userId)
        .collection('Pembelian')
        .where('Tanggal', isGreaterThanOrEqualTo: '$_selectedMonth-01')
        .where('Tanggal', isLessThan: _getNextMonthDate())
        .orderBy('Tanggal', descending: true);

    await Future.wait([
      _loadBarangData(),
      _loadPembelianData(),
    ]);
  }

  String _getNextMonthDate() {
    final date = DateTime.parse('$_selectedMonth-01');
    return DateFormat('yyyy-MM').format(DateTime(date.year, date.month + 1, 1));
  }

  Future<void> _loadBarangData() async {
    try {
      final userId = DatabaseMethods().currentUserId;
      final snapshot = await _db
          .collection('Users')
          .doc(userId)
          .collection('Barang')
          .get();
          
      _barangCache.clear();
      for (var doc in snapshot.docs) {
        var data = doc.data();
        _barangCache[doc.id] = {
          ...data,
          'id': doc.id,
          'originalJumlah': data['Jumlah'],
        };
      }
      setState(() => _isLoadingBarang = false);
    } catch (e) {
      print('Error loading barang: $e');
      setState(() => _isLoadingBarang = false);
      _showError("Gagal memuat data barang");
    }
  }

  Future<void> _loadPembelianData() async {
    try {
      // Update query untuk memastikan filtering yang benar
      final userId = DatabaseMethods().currentUserId;
      final startDate = '$_selectedMonth-01';
      final endDate = _getNextMonthDate();
      
      final snapshot = await _db
          .collection('Users')
          .doc(userId)
          .collection('Pembelian')
          .where('Tanggal', isGreaterThanOrEqualTo: startDate)
          .where('Tanggal', isLessThan: endDate)
          .get();

      setState(() {
        _pembelianDocs = snapshot.docs;
        _isLoadingPembelian = false;
      });
      _processPembelianData();
    } catch (e) {
      print('Error loading pembelian: $e');
      setState(() => _isLoadingPembelian = false);
      _showError("Gagal memuat data pembelian");
    }
  }

  void _processPembelianData() {
    _combinedData.clear();
    
    for (var barangData in _barangCache.values) {
      if (barangData['Tanggal'] != null &&
          barangData['Tanggal'].startsWith(_selectedMonth)) {
        final key = "${barangData['Name']}_${barangData['Tipe']}";
        _combinedData[key] = {
          "name": barangData["Name"],
          "tipe": barangData["Tipe"] ?? "Default",
          "persAwal": barangData["originalJumlah"] ?? 0,
          "pembelian": 0,
          "total": barangData["originalJumlah"] ?? 0,
          "satuan": barangData["Satuan"] ?? "N/A",
        };
      }
    }

    for (var doc in _pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final barangData = _barangCache[data["BarangId"]];
      if (barangData != null) {
        final key = "${barangData['Name']}_${data['Type']}";
        
        if (!_combinedData.containsKey(key)) {
          _combinedData[key] = {
            "name": barangData["Name"],
            "tipe": data["Type"],
            "persAwal": 0,
            "pembelian": 0,
            "total": 0,
            "satuan": barangData["Satuan"] ?? "N/A",
          };
        }

        _combinedData[key]!["pembelian"] += (data["Jumlah"] as num).toInt();
        _combinedData[key]!["total"] = 
            _combinedData[key]!["persAwal"] + _combinedData[key]!["pembelian"];
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoadingPembelian = true);
    await _loadPembelianData();
  }

  // Widget _buildMonthDropdown() {
  //   return Container(
  //     margin: EdgeInsets.all(16),
  //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.1),
  //           spreadRadius: 0,
  //           blurRadius: 20,
  //           offset: Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: Color(0xFFEEF2FF),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(
  //             Icons.calendar_today_rounded,
  //             color: Color(0xFF080C67),
  //             size: 20,
  //           ),
  //         ),
  //         SizedBox(width: 12),
  //         Text(
  //           "Filter Bulan:",
  //           style: TextStyle(
  //             fontWeight: FontWeight.w600,
  //             fontSize: 16,
  //             color: Color(0xFF080C67),
  //           ),
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: Container(
  //             padding: EdgeInsets.symmetric(horizontal: 12),
  //             decoration: BoxDecoration(
  //               border: Border.all(color: Colors.grey.withOpacity(0.2)),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //                 isExpanded: true,
  //                 value: _selectedMonth,
  //                 icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF080C67)),
  //                 items: _months.map((month) {
  //                   return DropdownMenuItem(
  //                     value: month,
  //                     child: Text(DateFormat('MMMM yyyy').format(DateTime.parse('$month-01'))),
  //                   );
  //                 }).toList(),
  //                 onChanged: (newValue) {
  //                   if (newValue != null && newValue != _selectedMonth) {
  //                     setState(() {
  //                       _selectedMonth = newValue;
  //                       _isLoadingPembelian = true;
  //                     });
  //                     _loadPembelianData();
  //                   }
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Map<String, List<QueryDocumentSnapshot>> _groupPurchasesByStore() {
  Map<String, List<QueryDocumentSnapshot>> groupedPurchases = {};
  
  for (var doc in _pembelianDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final storeName = data['NamaToko'] ?? 'N/A';
    
    if (!groupedPurchases.containsKey(storeName)) {
      groupedPurchases[storeName] = [];
    }
    groupedPurchases[storeName]!.add(doc);
  }
  
  return groupedPurchases;
}

  // Widget _buildActionButtons() {
  //   return Padding(
  //     padding: EdgeInsets.all(16),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       children: [
  //         // Tombol Tambah Pembelian
  //         Container(
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Color(0xFF080C67).withOpacity(0.3),
  //                 spreadRadius: 0,
  //                 blurRadius: 12,
  //                 offset: Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               onTap: () async {
  //                 final result = await Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => const InputPembelianPage(),
  //                   ),
  //                 );
  //                 if (result == true) {
  //                   _refreshData();
  //                 }
  //               },
  //               borderRadius: BorderRadius.circular(12),
  //               child: Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
  //                     SizedBox(width: 8),
  //                     Text(
  //                       'Input Pembelian',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

Widget _buildDataTable() {
  final groupedPurchases = _groupPurchasesByStore();
  
  return Container(
    margin: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Data Pembelian",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Color(0xFFEEF2FF)),
            columns: const [
              DataColumn(label: Text("Nama Toko")),
              DataColumn(label: Text("Total Items")),
              DataColumn(label: Text("Aksi")),
            ],
            rows: groupedPurchases.entries.map((entry) {
              final storeName = entry.key;
              final purchases = entry.value;
              
              return DataRow(cells: [
                DataCell(Text(storeName)),
                DataCell(Text(purchases.length.toString())),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility_rounded, color: Color(0xFF080C67)),
                      onPressed: () => _showStoreInvoicePreview(storeName, purchases),
                      tooltip: 'Lihat Invoice',
                    ),
                    IconButton(
                      icon: Icon(Icons.print_rounded, color: Color(0xFF080C67)),
                      onPressed: () => _generateStorePdf(storeName, purchases),
                      tooltip: 'Cetak PDF',
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

Future<void> _generateStorePdf(String storeName, List<QueryDocumentSnapshot> purchases) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    double totalAmount = 0;
    final selectedMonthDate = DateTime.parse('${_selectedMonth}-01');
    final monthYearStr = DateFormat('MMMM yyyy').format(selectedMonthDate);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Company Info
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _businessData['Nama Usaha'] ?? 'NAMA USAHA',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 20,
                              color: PdfColor.fromHex('#080C67'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _businessData['Tipe Usaha'] ?? 'Tipe Usaha',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                          pw.Text(
                            'Tel: ${_businessData['Nomor Telepon'] ?? '-'}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Supplier Info
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  margin: pw.EdgeInsets.symmetric(vertical: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EEF2FF'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Supplier:',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        storeName,
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Periode: $monthYearStr',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EEF2FF'),
                      ),
                      children: [
                        _buildPdfCell('Nama Barang', font: fontBold, align: pw.TextAlign.left),
                        _buildPdfCell('Jumlah', font: fontBold, align: pw.TextAlign.center),
                        _buildPdfCell('Harga', font: fontBold, align: pw.TextAlign.right),
                        _buildPdfCell('Tanggal', font: fontBold, align: pw.TextAlign.center),
                        _buildPdfCell('Total', font: fontBold, align: pw.TextAlign.right),
                      ],
                    ),
                    // Items
                    ...purchases.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final itemTotal = (data['Jumlah'] as int) * (data['Price'] as int);
                      totalAmount += itemTotal;

                      return pw.TableRow(
                        children: [
                          _buildPdfCell(
                            '${data['Name']}\n(${data['Type']})',
                            font: font,
                            align: pw.TextAlign.left,
                          ),
                          _buildPdfCell(
                            '${data['Jumlah']} ${data['Satuan']}',
                            font: font,
                            align: pw.TextAlign.center,
                          ),
                          _buildPdfCell(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(data['Price']),
                            font: font,
                            align: pw.TextAlign.right,
                          ),
                          _buildPdfCell(
                            data['Tanggal'] ?? '-',
                            font: font,
                            align: pw.TextAlign.center,
                          ),
                          _buildPdfCell(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(itemTotal),
                            font: font,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                // Total
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  padding: pw.EdgeInsets.only(top: 20),
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#080C67'),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'Total Pembelian: ',
                          style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totalAmount),
                          style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

pw.Widget _buildPdfCell(
  String text, {
  required pw.Font font,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Container(
    padding: pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 10),
      textAlign: align,
    ),
  );
}

 void _showStoreInvoicePreview(String storeName, List<QueryDocumentSnapshot> purchases) {
    final selectedMonthDate = DateTime.parse('${_selectedMonth}-01');
    final monthYearStr = DateFormat('MMMM yyyy').format(selectedMonthDate);
    double totalAmount = 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Toko $storeName',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Info
                    Text(
                      _businessData['Nama Usaha'] ?? 'NAMA USAHA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF080C67),
                      ),
                    ),
                    Text(_businessData['Tipe Usaha'] ?? 'Tipe Usaha'),
                    Text('Tel: ${_businessData['Nomor Telepon'] ?? '-'}'),
                    SizedBox(height: 24),

                    // Store Info
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF080C67),
                            ),
                          ),
                          Text(storeName),
                          Text(
                            'Periode: $monthYearStr',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Nama Barang')),
                                Expanded(flex: 1, child: Text('Jumlah')),
                                Expanded(flex: 2, child: Text('Harga')),
                                Expanded(flex: 2, child: Text('Total')),
                              ],
                            ),
                          ),
                          ...purchases.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final itemTotal = (data['Jumlah'] as int) * (data['Price'] as int);
                            totalAmount += itemTotal;
                            
                            return Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['Name']),
                                        Text(
                                          data['Type'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('${data['Jumlah']} ${data['Satuan']}'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp ',
                                        decimalDigits: 0,
                                      ).format(data['Price']),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp ',
                                        decimalDigits: 0,
                                      ).format(itemTotal),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Total
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF080C67),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembelian',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(totalAmount),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHeaderSection() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // Filter Bulan button
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showMonthPicker();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF080C67),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(
                        DateTime.parse('$_selectedMonth-01'),
                      ),
                      style: TextStyle(
                        color: Color(0xFF080C67),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Input Pembelian button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InputPembelianPage(),
                ),
              );
              if (result == true) {
                _refreshData();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF080C67).withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Input Pembelian",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _showMonthPicker() {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Pilih Bulan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];
                final isSelected = month == _selectedMonth;
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedMonth = month;
                      _isLoadingPembelian = true;
                    });
                    _loadPembelianData();
                    Navigator.pop(context);
                  },
                  title: Text(
                    DateFormat('MMMM yyyy').format(
                      DateTime.parse('$month-01'),
                    ),
                    style: TextStyle(
                      color: isSelected ? Color(0xFF080C67) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Color(0xFF080C67))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
@override
Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Pembelian',
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
          ),
        ),
      ),
      body: _isLoadingBusinessData
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    if (_isLoadingPembelian)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
                          ),
                        ),
                      )
                    else
                      _buildDataTable(),
                  ],
                ),
              ),
            ),
    );
  }
}
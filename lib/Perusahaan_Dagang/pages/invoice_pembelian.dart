import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/service/database.dart';

class InvoicePembelianPage extends StatefulWidget {
  final String selectedMonth;
  final List<QueryDocumentSnapshot> pembelianDocs;
  
  const InvoicePembelianPage({
    Key? key, 
    required this.selectedMonth,
    required this.pembelianDocs,
  }) : super(key: key);

  @override
  State<InvoicePembelianPage> createState() => _InvoicePembelianPageState();
}

class _InvoicePembelianPageState extends State<InvoicePembelianPage> {
  late DataUsahaController dataUsahaC;
  
  @override
  void initState() {
    super.initState();
    String currentUserUid = DatabaseMethods().currentUserId;
    dataUsahaC = Get.put(DataUsahaController(uid: currentUserUid));
    _loadDataUsaha();
  }

  Future<void> _loadDataUsaha() async {
    await dataUsahaC.fetchDataUsaha(DatabaseMethods().currentUserId);
  }

  // Calculate totals
  Map<String, double> _calculateTotals() {
    double totalSubtotal = 0;
    for (var doc in widget.pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalSubtotal += (data['Jumlah'] * data['Price']).toDouble();
    }
    
    final ppn = totalSubtotal * 0.12;
    final total = totalSubtotal + ppn;
    
    return {
      'subtotal': totalSubtotal,
      'ppn': ppn,
      'total': total,
    };
  }

  Future<void> _generateAndPrintPdf() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final totals = _calculateTotals();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            dataUsahaC.namaUsaha.value,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 20,
                              color: PdfColor.fromHex('#080C67'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Jalan Contoh No. 123, Kota, Provinsi',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                          pw.Text(
                            'Tel: ${dataUsahaC.nomorTelepon.value}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'INVOICE PEMBELIAN',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: PdfColor.fromHex('#080C67'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Periode: ${DateFormat('MMMM yyyy').format(DateTime.parse('${widget.selectedMonth}-01'))}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table
                 pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EEF2FF'),
                      ),
                      children: [
                        _buildTableCell('No', font: fontBold, align: pw.TextAlign.center),
                        _buildTableCell('Item', font: fontBold),
                        _buildTableCell('Qty', font: fontBold, align: pw.TextAlign.right),
                        _buildTableCell('Harga', font: fontBold, align: pw.TextAlign.right),
                        _buildTableCell('Tanggal', font: fontBold, align: pw.TextAlign.center),
                        _buildTableCell('Subtotal', font: fontBold, align: pw.TextAlign.right),
                      ],
                    ),
                    // Table Content
                    ...widget.pembelianDocs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;
                      final subtotal = data['Jumlah'] * data['Price'];
                      final bgColor = index % 2 == 0 ? null : PdfColor.fromHex('#F8FAFC');

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: bgColor),
                        children: [
                          _buildTableCell('${index + 1}', font: font, align: pw.TextAlign.center),
                          _buildTableCell('${data['Name']} (${data['Type']})', font: font),
                          _buildTableCell('${data['Jumlah']} ${data['Satuan']}', font: font, align: pw.TextAlign.right),
                          _buildTableCell(
                            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(data['Price']),
                            font: font,
                            align: pw.TextAlign.right,
                          ),
                          _buildTableCell(data['Tanggal'] ?? '-', font: font, align: pw.TextAlign.center),
                          _buildTableCell(
                            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(subtotal),
                            font: font,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Totals Section
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildTotalRow('Subtotal:', totals['subtotal']!, font, fontBold),
                      _buildTotalRow('PPN (12%):', totals['ppn']!, font, fontBold),
                      pw.Divider(color: PdfColors.grey300),
                      _buildTotalRow('Total:', totals['total']!, font, fontBold, isTotal: true),
                    ],
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

  pw.Widget _buildTableCell(
    String text, {
    required pw.Font font,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double amount,
    pw.Font font,
    pw.Font fontBold, {
    bool isTotal = false,
  }) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: isTotal ? fontBold : font,
                color: isTotal ? PdfColor.fromHex('#080C67') : PdfColors.black,
              ),
            ),
          ),
          pw.Container(
            width: 150,
            child: pw.Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(amount),
              style: pw.TextStyle(
                font: isTotal ? fontBold : font,
                color: isTotal ? PdfColor.fromHex('#080C67') : PdfColors.black,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Invoice Pembelian ${DateFormat('MMMM yyyy').format(DateTime.parse('${widget.selectedMonth}-01'))}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.print, color: Colors.white),
                onPressed: _generateAndPrintPdf,
                tooltip: 'Cetak Invoice',
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Info Card
            Container(
              padding: EdgeInsets.all(20),
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
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataUsahaC.namaUsaha.value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF080C67),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Jalan Contoh No. 123, Kota, Provinsi', 
                    style: TextStyle(color: Colors.grey[600])),
                  Text('Tel: ${dataUsahaC.nomorTelepon.value}', 
                    style: TextStyle(color: Colors.grey[600])),
                ],
              )),
            ),
            SizedBox(height: 20),

            // Transactions Table
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
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
                        DataColumn(label: Text('No')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Harga')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Subtotal')),
                      ],
                      rows: List.generate(widget.pembelianDocs.length, (index) {
                        final data = widget.pembelianDocs[index].data() as Map<String, dynamic>;
                        final subtotal = data['Jumlah'] * data['Price'];
                        
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                            if (index % 2 == 0) return Colors.grey.withOpacity(0.05);
                            return null;
                          }),
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text('${data['Name']} (${data["Type"]})')),
                            DataCell(Text('${data["Jumlah"]} ${data["Satuan"]}')),
                            DataCell(Text(NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(data["Price"]))),
                            DataCell(Text(data['Tanggal'] ?? '-')),
                            DataCell(Text(NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(subtotal))),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),

            // Totals Card with Summary
            Container(
              padding: EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 150,
                        child: Text('Subtotal'),
                      ),
                      Container(
                        width: 150,
                        child: Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totals['subtotal']),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 150,
                        child: Text('PPN (12%)'),
                      ),
                      Container(
                        width: 150,
                        child: Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totals['ppn']),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 150,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF080C67),
                          ),
                        ),
                      ),
                      Container(
                        width: 150,
                        child: Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(totals['total']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF080C67),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
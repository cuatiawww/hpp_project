import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/service/database.dart';

class InvoiceDetailDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const InvoiceDetailDialog({Key? key, required this.data}) : super(key: key);

  @override
  State<InvoiceDetailDialog> createState() => _InvoiceDetailDialogState();
}

class _InvoiceDetailDialogState extends State<InvoiceDetailDialog> {
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

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.data['total'];
    // final ppn = subtotal * 0.12;
    final total = subtotal;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFF080C67),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Info
                  Text(
                    dataUsahaC.namaUsaha.value.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Jalan Contoh No. 123, Kota, Provinsi',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Tel: ${dataUsahaC.nomorTelepon.value}',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Email: email@usaha.com',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 16),

                  // Invoice Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice No:',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Tanggal:',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.data['tanggal'],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Detail Items Header
                  Text(
                    'Detail Item',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Item Details
                  _buildSimpleRow('Nama Barang', widget.data['namaBarang']),
                  _buildSimpleRow('Tipe', widget.data['tipe']),
                  _buildSimpleRow('Jumlah', '${widget.data['jumlah']} ${widget.data['satuan']}'),
                  _buildSimpleRow(
                    'Harga Satuan',
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(widget.data['hargaJual']),
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  
                  // Totals
                  _buildSimpleRow(
                    'Subtotal',
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(subtotal),
                  ),
                  // _buildSimpleRow(
                  //   'PPN (12%)',
                  //   NumberFormat.currency(
                  //     locale: 'id',
                  //     symbol: 'Rp ',
                  //     decimalDigits: 0,
                  //   ).format(ppn),
                  // ),
                  SizedBox(height: 8),
                  _buildSimpleRow(
                    'Total',
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(total),
                    isBold: true,
                  ),
                  SizedBox(height: 16),

                  // Print Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateAndPrintPdf,
                      icon: Icon(Icons.print, size: 18),
                      label: Text('Cetak Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF080C67),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintPdf() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    
    final subtotal = widget.data['total'];
    // final ppn = subtotal * 0.12;
    final total = subtotal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
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
                            'INVOICE PENJUALAN',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: PdfColor.fromHex('#080C67'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'No. INV-${DateTime.now().millisecondsSinceEpoch}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                          pw.Text(
                            'Tanggal: ${widget.data['tanggal']}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Item Details
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Detail Item',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColor.fromHex('#080C67'),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      _buildPdfDetailRow('Nama Barang:', widget.data['namaBarang'], font),
                      _buildPdfDetailRow('Tipe:', widget.data['tipe'], font),
                      _buildPdfDetailRow('Jumlah:', '${widget.data['jumlah']} ${widget.data['satuan']}', font),
                      _buildPdfDetailRow(
                        'Harga Satuan:',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(widget.data['hargaJual']),
                        font,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfDetailRow(
                        'Subtotal:',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(subtotal),
                        font,
                      ),
                      // _buildPdfDetailRow(
                      //   'PPN (12%):',
                      //   NumberFormat.currency(
                      //     locale: 'id',
                      //     symbol: 'Rp ',
                      //     decimalDigits: 0,
                      //   ).format(ppn),
                      //   font,
                      // ),
                      pw.Divider(),
                      _buildPdfDetailRow(
                        'Total:',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(total),
                        fontBold,
                        isBold: true,
                      ),
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

  pw.Widget _buildPdfDetailRow(String label, String value, pw.Font font, {bool isBold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font),
          ),
        ],
      ),
    );
  }
}
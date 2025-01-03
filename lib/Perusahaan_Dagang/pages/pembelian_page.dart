import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/input_pembelian_page.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/invoice_pembelian.dart';
import 'package:hpp_project/service/database.dart';
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
  
  // State variables
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  // Loading states
  bool _isLoadingBarang = true;
  bool _isLoadingPembelian = true;
  
  // Firebase references
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Query _pembelianQuery;

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _initializeData();
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

  Widget _buildMonthDropdown() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
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
            "Filter Bulan:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedMonth,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF080C67)),
                  items: _months.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MMMM yyyy').format(DateTime.parse('$month-01'))),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null && newValue != _selectedMonth) {
                      setState(() {
                        _selectedMonth = newValue;
                        _isLoadingPembelian = true;
                      });
                      _loadPembelianData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Tambah Pembelian
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF080C67), Color(0xFF1E23A7)],
              ),
              borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Input Pembelian',
                        style: TextStyle(
                          color: Colors.white,
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

Widget _buildDataTable() {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Data Pembelian",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
              // Invoice Bulanan Button
              ElevatedButton.icon(
                onPressed: () => _showMonthlyInvoice(),
                icon: Icon(Icons.assessment_rounded),
                label: Text('Invoice Bulanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF080C67),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Color(0xFFEEF2FF)),
            columns: const [
              DataColumn(label: Text("Nama Barang")),
              DataColumn(label: Text("Jumlah")),
              DataColumn(label: Text("Harga per Unit")),
              DataColumn(label: Text("Tipe")),
              DataColumn(label: Text("Tanggal")),
              DataColumn(label: Text("Aksi")),
            ],
            rows: _pembelianDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(data['Name'] ?? "Loading...")),
                DataCell(Text(data["Jumlah"]?.toString() ?? "0")),
                DataCell(Text(NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(data["Price"] ?? 0))),
                DataCell(Text(data["Type"] ?? "")),
                DataCell(Text(data["Tanggal"] ?? "")),
                DataCell(IconButton(
                  icon: Icon(Icons.receipt_rounded, color: Color(0xFF080C67)),
                  onPressed: () => _showInvoicePreview(doc.id, data),
                  tooltip: 'Lihat Invoice',
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

void _showInvoicePreview(String pembelianId, Map<String, dynamic> data) {
  final subtotal = data['Jumlah'] * data['Price'];
  final ppn = subtotal * 0.12;
  final total = subtotal + ppn;

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
                  'Preview Invoice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // IconButton(
                    //   icon: Icon(Icons.print, color: Colors.white),
                    //   onPressed: () {
                    //     Navigator.pop(context);
                    //     _printSingleInvoice(pembelianId, data);
                    //   },
                    //   tooltip: 'Cetak Invoice',
                    // ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
                    'NAMA USAHA ANDA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF080C67),
                    ),
                  ),
                  Text('Jalan Contoh No. 123, Kota, Provinsi'),
                  Text('Tel: (021) 1234567'),
                  Text('Email: email@usaha.com'),
                  SizedBox(height: 24),

                  // Invoice Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice No:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('INV-${pembelianId.substring(0, 8)}'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tanggal:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(data['Tanggal']),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Item Details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF080C67),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow('Nama Barang', data['Name']),
                        _buildDetailRow('Tipe', data['Type']),
                        _buildDetailRow(
                          'Jumlah', 
                          '${data['Jumlah']} ${data['Satuan']}'
                        ),
                        _buildDetailRow(
                          'Harga Satuan',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(data['Price']),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Totals
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Subtotal',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(subtotal),
                        ),
                        _buildDetailRow(
                          'PPN (12%)',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(ppn),
                        ),
                        Divider(height: 16),
                        _buildDetailRow(
                          'Total',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(total),
                          isBold: true,
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

Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}


void _showMonthlyInvoice() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InvoicePembelianPage(
        selectedMonth: _selectedMonth,
        pembelianDocs: _pembelianDocs,
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
    body: RefreshIndicator(
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
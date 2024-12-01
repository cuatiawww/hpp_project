import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/perusahaan_dagang/pages/invoice_detail.dart';
import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
   // Controllers
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  
  // State variables
  String? _selectedBarang; // Tambahkan ini
  String? _selectedTipe;
  List<String> _tipeList = [];
  final TextEditingController _hargaBeliController = TextEditingController();
  double _totalHarga = 0;
  DateTime _selectedDate = DateTime.now(); // Tambahkan ini
  bool _isLoading = false;
  
  
  // Firebase reference
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }
  

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF080C67),
              Color(0xFF1E23A7),
            ],
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
            'Penjualan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    ),
    body: Container(
      color: Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            SizedBox(height: 24),
            _buildReportCard(),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInputCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
          Text(
            'Input Penjualan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 24),
          _buildBarangDropdown(),
          SizedBox(height: 16),
          _buildTipeDropdown(),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Jumlah Unit',
            controller: _unitController,
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotal(),
          ),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Harga Jual per Unit',
            controller: _priceController,
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotal(),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF080C67),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF080C67),
                      ),
                    ),
                  ],
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_totalHarga),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF080C67),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Tanggal',
            controller: _tanggalController,
            icon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
          ),
          SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF080C67),
                  Color(0xFF1E23A7),
                ],
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
                onTap: _isLoading ? null : _submitPenjualan,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Simpan Penjualan',
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

  Widget _buildReportCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
          Text(
            'Report Invoice',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 24),
          _buildInvoiceList(),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseMethods().getPenjualanStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  "Belum ada data penjualan",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF080C67),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  data['namaBarang'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF080C67),
                  ),
                ),
                subtitle: Text(
                  '${data['jumlah']} ${data['satuan']} - ${data['tipe']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(data['total']),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF080C67),
                      ),
                    ),
                    Text(
                      data['tanggal'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                onTap: () => _showInvoiceDetail(data),
              ),
            );
          },
        );
      },
    );
  }

Widget _buildBarangDropdown() {
  return FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: DatabaseMethods().getAvailableStock(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
            ),
          ),
        );
      }

      var availableStock = snapshot.data!;
      var stockWithInventory = availableStock.entries
          .where((entry) => entry.value['jumlah'] > 0)
          .map((entry) => DropdownMenuItem<String>(
                value: '${entry.value['name']}_${entry.value['tipe']}',
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        TextSpan(text: entry.value['name']),
                        TextSpan(text: ' (${entry.value['tipe']})'),
                        TextSpan(text: ' - ${entry.value['jumlah']} ${entry.value['satuan']}'),
                      ],
                    ),
                  ),
                ),
              ))
          .toList();

      return _buildDropdownField(
        label: 'Pilih Barang',
        icon: Icons.inventory_2_rounded,
        child: DropdownButton<String>(
          value: _selectedBarang,
          items: stockWithInventory,
          onChanged: (value) {
            if (value != null) {
              final selectedStock = availableStock[value];
              setState(() {
                _selectedBarang = value;
                if (selectedStock != null) {
                  _selectedTipe = selectedStock['tipe'] as String?;
                  _tipeList = [selectedStock['tipe'] as String? ?? '']
                      .where((t) => t.isNotEmpty)
                      .toList();
                }
              });
            }
          },
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, size: 24),
          selectedItemBuilder: (BuildContext context) {
            return stockWithInventory.map<Widget>((item) {
              final value = item.value!.split('_');
              return Container(
                alignment: Alignment.centerLeft,
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                child: Text(
                  value[0], // Hanya tampilkan nama barang saat terpilih
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              );
            }).toList();
          },
        ),
      );
    },
  );
}

// Update _buildTipeDropdown untuk menangani kasus ketika hanya ada satu tipe
Widget _buildTipeDropdown() {
  return _buildDropdownField(
    label: 'Pilih Tipe',
    icon: Icons.category_rounded,
    child: DropdownButtonFormField<String>(
      value: _selectedTipe,
      items: _tipeList.map((String tipe) {
        return DropdownMenuItem(
          value: tipe,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            child: Text(
              tipe,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: _tipeList.isEmpty ? null : (value) {
        setState(() {
          _selectedTipe = value;
        });
      },
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        hintText: _tipeList.isEmpty ? 'Pilih barang terlebih dahulu' : null,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, size: 24),
      selectedItemBuilder: (BuildContext context) {
        return _tipeList.map<Widget>((String tipe) {
          return Container(
            alignment: Alignment.centerLeft,
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            child: Text(
              tipe,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          );
        }).toList();
      },
    ),
  );
}
  
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF080C67),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Color(0xFF080C67),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildDropdownField({
  required String label,
  required IconData icon,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF080C67),
        ),
      ),
      SizedBox(height: 8),
      Container(
        height: 48, // Fixed height untuk dropdown container
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                color: Color(0xFF080C67),
                size: 20,
              ),
            ),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: child,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  void _showInvoiceDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => InvoiceDetailDialog(data: data),
    );
  }
  void _calculateTotal() {
    if (_unitController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      setState(() {
        _totalHarga = double.parse(_unitController.text) * 
                      double.parse(_priceController.text);
      });
    }
  }

  void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFC0392B),
              Color(0xFFE74C3C),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
      ),
      duration: Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
void _showSuccess(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E8449),
              Color(0xFF27AE60),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Berhasil!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
      ),
      duration: Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _submitPenjualan() async {
  if (_selectedBarang == null || 
      _selectedTipe == null ||  
      _unitController.text.isEmpty || 
      _priceController.text.isEmpty) {
    _showError('Mohon lengkapi semua field');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final userId = DatabaseMethods().currentUserId;
    final availableStock = await DatabaseMethods().getAvailableStock();
    final selectedStock = availableStock[_selectedBarang];
    
    if (selectedStock == null) {
      throw 'Barang tidak ditemukan';
    }

    final int currentStock = selectedStock['jumlah'] as int;
    final int jumlahJual = int.parse(_unitController.text);

    if (currentStock < jumlahJual) {
      throw 'Stok tidak mencukupi. Stok tersedia: $currentStock ${selectedStock['satuan']}';
    }

    // Mulai batch operation
    final batch = _db.batch();
    
    // Tambah data penjualan
    final penjualanRef = _db
        .collection("Users")
        .doc(userId)
        .collection("Penjualan")
        .doc();

    batch.set(penjualanRef, {
      'barangId': selectedStock['id'],
      'namaBarang': selectedStock['name'],
      'tipe': selectedStock['tipe'],
      'jumlah': jumlahJual,
      'hargaJual': int.parse(_priceController.text),
      'satuan': selectedStock['satuan'],
      'tanggal': _tanggalController.text,
      'total': jumlahJual * int.parse(_priceController.text),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Reset form
    setState(() {
      _selectedBarang = null;
      _selectedTipe = null;
      _unitController.clear();
      _priceController.clear();
      _totalHarga = 0;
      _selectedDate = DateTime.now();
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });

    _showSuccess('Barang berhasil terjual');
  } catch (e) {
    _showError('Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
  @override
  void dispose() {
    _unitController.dispose();
    _priceController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
}


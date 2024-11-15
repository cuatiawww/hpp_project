import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';
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
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF080C67),
                Color(0xFF1E23A7),
              ],
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
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseMethods().getBarangDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
          );
        }

        List<DropdownMenuItem<String>> items = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return DropdownMenuItem(
            value: doc.id,
            child: Text(data['Name'] ?? 'Unnamed'),
          );
        }).toList();

        return _buildDropdownField(
          label: 'Pilih Barang',
          icon: Icons.inventory_2_rounded,
          child: DropdownButtonFormField<String>(
            value: _selectedBarang,
            items: items,
            onChanged: (value) {
              setState(() {
                _selectedBarang = value;
                _selectedTipe = null;
              });
              if (value != null) {
                _updateTipeList(value);
              }
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipeDropdown() {
    return _buildDropdownField(
      label: 'Pilih Tipe',
      icon: Icons.category_rounded,
      child: DropdownButtonFormField<String>(
        value: _selectedTipe,
        items: _tipeList.map((String tipe) {
          return DropdownMenuItem(
            value: tipe,
            child: Text(tipe),
          );
        }).toList(),
        onChanged: _selectedBarang == null ? null : (value) {
          setState(() {
            _selectedTipe = value;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
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
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  icon,
                  color: Color(0xFF080C67),
                  size: 20,
                ),
              ),
              Expanded(child: child),
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

  void _updateTipeList(String barangId) async {
    final userId = DatabaseMethods().currentUserId;
    try {
      final barangDoc = await _db
          .collection('Users')
          .doc(userId)
          .collection('Barang')
          .doc(barangId)
          .get();

      final pembelianDocs = await _db
          .collection('Users')
          .doc(userId)
          .collection('Pembelian')
          .where('BarangId', isEqualTo: barangId)
          .get();

      Set<String> tipeSet = {};
      
      if (barangDoc.exists) {
        tipeSet.add(barangDoc.data()!['Tipe']);
      }

      for (var doc in pembelianDocs.docs) {
        tipeSet.add(doc.data()['Type']);
      }

      setState(() {
        _tipeList = tipeSet.where((tipe) => tipe != null).toList();
        _selectedTipe = _tipeList.isNotEmpty ? _tipeList[0] : null;
      });
    } catch (e) {
      print('Error loading tipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memuat tipe barang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



Future<void> _submitPenjualan() async {
    if (_selectedBarang == null || 
        _unitController.text.isEmpty || 
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = DatabaseMethods().currentUserId;
      final barangDoc = await _db
          .collection('Users')
          .doc(userId)
          .collection('Barang')
          .doc(_selectedBarang)
          .get();

      if (!barangDoc.exists) {
        throw 'Barang tidak ditemukan';
      }

      final barangData = barangDoc.data()!;
      
      await _db
          .collection('Users')
          .doc(userId)
          .collection('Penjualan')  // Path yang benar
          .add({
        'barangId': _selectedBarang,
        'namaBarang': barangData['Name'],
        'tipe': _selectedTipe,
        'jumlah': int.parse(_unitController.text),
        'hargaJual': int.parse(_priceController.text),
        'satuan': barangData['Satuan'],
        'tanggal': _tanggalController.text,
        'total': int.parse(_unitController.text) * int.parse(_priceController.text),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Tambah notifikasi
      await addPenjualanNotification(
        namaBarang: barangData['Name'],
        jumlah: int.parse(_unitController.text),
        satuan: barangData['Satuan'],
        tipe: _selectedTipe ?? '',
      );

      // Reset form
      setState(() {
        _selectedBarang = null;
        _selectedTipe = null;
        _unitController.clear();
        _priceController.clear();
        _selectedDate = DateTime.now();
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Penjualan berhasil disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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


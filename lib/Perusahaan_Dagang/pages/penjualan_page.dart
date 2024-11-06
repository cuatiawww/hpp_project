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
  void _updateTipeList(String barangId) async {
    final userId = DatabaseMethods().currentUserId;
    try {
      // Get tipe from Barang
      final barangDoc = await _db
          .collection('Users')
          .doc(userId)
          .collection('Barang')
          .doc(barangId)
          .get();

      // Get tipe from Pembelian
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
    }
  }
  void _calculateTotal() {
    if (_unitController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      setState(() {
        _totalHarga = double.parse(_unitController.text) * 
                      double.parse(_priceController.text);
      });
    }
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
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF080C67),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Input Penjualan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Pilih Barang Dropdown
                    StreamBuilder<QuerySnapshot>(
                      stream: DatabaseMethods().getBarangDetails(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        List<DropdownMenuItem<String>> items = snapshot.data!.docs
                            .map((doc) {
                          Map<String, dynamic> data = 
                              doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['Name'] ?? 'Unnamed'),
                          );
                        }).toList();

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Pilih Barang',
                            border: OutlineInputBorder(),
                          ),
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
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Tipe Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Pilih Tipe',
                        border: OutlineInputBorder(),
                      ),
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
                    ),
                    SizedBox(height: 16),
                    // Input Unit
                    TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                    ),
                    SizedBox(height: 16),
                    // Harga Jual
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Harga Jual per Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotal(),
                    ),
                    SizedBox(height: 16),
                    // Total
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(_totalHarga),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Tanggal
                    TextFormField(
                      controller: _tanggalController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
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
                            _tanggalController.text = 
                                DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
  onPressed: _isLoading ? null : _submitPenjualan,
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF080C67),
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
  child: _isLoading
      ? CircularProgressIndicator(color: Colors.white)
      : Text(
          'Simpan Penjualan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16, // Optional: tambahkan ukuran font jika perlu
          ),
        ),
),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Report Invoice Section
            // Report Invoice Section
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Report Invoice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Optional: Tambahkan button filter atau export
          ],
        ),
        Divider(height: 24),
        // Report Invoice Section
StreamBuilder<QuerySnapshot>(
  stream: DatabaseMethods().getPenjualanStream(),  // Gunakan method dari DatabaseMethods
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text('Belum ada data penjualan'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
        return ListTile(
          title: Text(data['namaBarang']),
          subtitle: Text('${data['jumlah']} ${data['satuan']} - ${data['tipe']}'),
          trailing: Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(data['total']),
          ),
          onTap: () => _showInvoiceDetail(data),
        );
      },
    );
  },
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
void _showInvoiceDetail(Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (context) => InvoiceDetailDialog(data: data),
  );
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


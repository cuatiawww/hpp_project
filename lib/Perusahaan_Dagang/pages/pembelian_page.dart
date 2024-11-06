import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  // Controllers
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  
  // Data holders
  final Map<String, Map<String, dynamic>> _barangCache = {};
  final Map<String, Map<String, dynamic>> _combinedData = {};
  final List<String> _months = [];
  List<QueryDocumentSnapshot> _pembelianDocs = [];
  
  // State variables
  String? _selectedBarang;
  bool _isDifferentType = false;
  DateTime _selectedDate = DateTime.now();
  late String _selectedMonth;
  
  // Loading states
  bool _isLoadingBarang = true;
  bool _isLoadingPembelian = true;
  bool _isSubmitting = false;
  
  // Firebase references
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Query _pembelianQuery;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('yyyy-MM').format(_selectedDate);
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _generateMonths();
    _initializeData();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  //DATABASES
  Future<void> _initializeData() async {
    setState(() {
      _isLoadingBarang = true;
      _isLoadingPembelian = true;
    });

    final userId = DatabaseMethods().currentUserId;
    _pembelianQuery = _db
        .collection('Users')
        .doc(userId)
        .collection('Pembelian')  // Path yang benar
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
    return DateFormat('yyyy-MM').format(
      DateTime(date.year, date.month + 1, 1)
    );
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
      setState(() {
        _isLoadingBarang = false;
      });
    } catch (e) {
      print('Error loading barang: $e');
      setState(() {
        _isLoadingBarang = false;
      });
      _showError("Gagal memuat data barang");
    }
}

Future<void> _loadPembelianData() async {
    try {
      final userId = DatabaseMethods().currentUserId;
      _pembelianQuery = _db
          .collection('Users')
          .doc(userId)
          .collection('Pembelian')
          .where('Tanggal', isGreaterThanOrEqualTo: '$_selectedMonth-01')
          .where('Tanggal', isLessThan: _getNextMonthDate())
          .orderBy('Tanggal', descending: true);

      final snapshot = await _pembelianQuery.get();
      setState(() {
        _pembelianDocs = snapshot.docs;
        _isLoadingPembelian = false;
      });
      _processPembelianData();
    } catch (e) {
      print('Error loading pembelian: $e');
      setState(() {
        _isLoadingPembelian = false;
      });
      _showError("Gagal memuat data pembelian");
    }
}
  void _processPembelianData() {
    _combinedData.clear();
    
    // Initialize hanya untuk data P.Awal yang benar-benar ada
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

    // Proses data pembelian
    for (var doc in _pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final barangData = _barangCache[data["BarangId"]];
      if (barangData != null) {
        final key = "${barangData['Name']}_${data['Type']}";
        
        // Jika ini adalah tipe baru yang tidak ada di P.Awal
        if (!_combinedData.containsKey(key)) {
          _combinedData[key] = {
            "name": barangData["Name"],
            "tipe": data["Type"],
            "persAwal": 0,  // Set P.Awal ke 0 untuk tipe baru
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingPembelian = true;
    });
    await _loadPembelianData();
  }

 Future<void> _tambahBarang() async {
    if (_isSubmitting) return;
    
    if (!_validateInput()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final barangData = _barangCache[_selectedBarang];
      if (barangData == null) throw Exception("Barang tidak ditemukan");

      final userId = DatabaseMethods().currentUserId;

      // Perbaiki collection path - tambahkan ke collection Pembelian di bawah Users/{userId}
      await _db.collection("Users")
          .doc(userId)
          .collection("Pembelian") // Path yang benar
          .add({
        "BarangId": barangData['id'],
        "Name": barangData['Name'],
        "Jumlah": int.parse(_unitController.text),
        "Price": _isDifferentType 
            ? int.parse(_priceController.text) 
            : barangData["Price"],
        "Type": _isDifferentType ? _typeController.text : barangData["Tipe"],
        "Satuan": barangData["Satuan"],
        "Timestamp": FieldValue.serverTimestamp(),
        "Tanggal": _tanggalController.text,
      });

      _showSuccess("Pembelian berhasil ditambahkan!");
      _resetForm();
      _refreshData();
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
}
  bool _validateInput() {
    if (_selectedBarang == null || 
        _unitController.text.isEmpty || 
        _tanggalController.text.isEmpty ||
        (_isDifferentType && (_typeController.text.isEmpty || _priceController.text.isEmpty))) {
      _showError("Harap isi semua field");
      return false;
    }
    return true;
  }

  void _resetForm() {
    setState(() {
      _selectedBarang = null;
      _unitController.clear();
      _typeController.clear();
      _priceController.clear();
      _isDifferentType = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
 @override
Widget build(BuildContext context) {
  if (_isLoadingBarang) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Pembelian',
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
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Pembelian',
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
    body: RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputForm(),
              const SizedBox(height: 16),
              _buildMonthFilter(),
              if (_isLoadingPembelian)
                const Center(child: CircularProgressIndicator())
              else
                _buildDataTables(),
            ],
          ),
        ),
      ),
    ),
  );
}
  Widget _buildInputForm() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Input Pembelian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Pilih Barang Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Pilih Barang',
              border: OutlineInputBorder(),
            ),
            value: _selectedBarang,
            hint: Text('Pilih Barang'),
            items: _barangCache.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value["Name"] ?? ""),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedBarang = value;
                final data = _barangCache[value]!;
                _priceController.text = data["Price"]?.toString() ?? "";
                _typeController.text = data["Tipe"] ?? "";
                _isDifferentType = false;
              });
            },
          ),
          SizedBox(height: 16),
          // Jumlah Unit
          TextFormField(
            controller: _unitController,
            decoration: InputDecoration(
              labelText: 'Jumlah Unit',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          // Type berbeda checkbox
          Row(
            children: [
              Checkbox(
                value: _isDifferentType,
                onChanged: (value) {
                  setState(() {
                    _isDifferentType = value ?? false;
                    if (!_isDifferentType && _selectedBarang != null) {
                      final data = _barangCache[_selectedBarang]!;
                      _typeController.text = data["Tipe"] ?? "";
                      _priceController.text = data["Price"]?.toString() ?? "";
                    }
                  });
                },
              ),
              Text("Type berbeda"),
            ],
          ),
          SizedBox(height: 16),
          // Tipe dan Harga conditionally shown
          if (_isDifferentType) ...[
            TextFormField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Type Barang',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Harga per Unit',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ] else
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Harga per Unit (tidak bisa diubah)',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              keyboardType: TextInputType.number,
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
            onTap: () => _selectDate(context),
          ),
          SizedBox(height: 24),
          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _tambahBarang,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF080C67),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Tambahkan Barang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildBarangDropdown() {
    final items = _barangCache.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value["Name"] ?? ""),
      );
    }).toList();

    return DropdownButton<String>(
      isExpanded: true,
      hint: const Text("Pilih Barang"),
      value: _selectedBarang,
      items: items,
      onChanged: (value) {
        if (value == null) return;
        
        setState(() {
          _selectedBarang = value;
          final data = _barangCache[value]!;
          _priceController.text = data["Price"]?.toString() ?? "";
          _typeController.text = data["Tipe"] ?? "";
          _isDifferentType = false;
        });
      },
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isDifferentType,
              onChanged: (value) {
                setState(() {
                  _isDifferentType = value ?? false;
                  if (!_isDifferentType && _selectedBarang != null) {
                    final data = _barangCache[_selectedBarang]!;
                    _typeController.text = data["Tipe"] ?? "";
                    _priceController.text = data["Price"]?.toString() ?? "";
                  }
                });
              },
            ),
            const Text("Type berbeda")
          ],
        ),
        if (_isDifferentType) ...[
          TextField(
            controller: _typeController,
            decoration: const InputDecoration(
              labelText: "Type Barang (input jika berbeda)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: "Harga per Unit",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ] else
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: "Harga per Unit (tidak bisa diubah)",
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }

  Widget _buildMonthFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Text(
            "Filter Bulan: ", 
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _selectedMonth,
            items: _months.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(DateFormat('MMMM yyyy')
                    .format(DateTime.parse('$month-01'))),
              );
            }).toList(),
            onChanged: (newValue) {
  if (newValue != null && newValue != _selectedMonth) {
    setState(() {
      _selectedMonth = newValue;
      _isLoadingPembelian = true;
    });
    
    final userId = DatabaseMethods().currentUserId;
    _pembelianQuery = _db
        .collection('Users')
        .doc(userId)
        .collection('Pembelian')  // Path yang benar
        .where('Tanggal', isGreaterThanOrEqualTo: '$newValue-01')
        .where('Tanggal', isLessThan: _getNextMonthDate())
        .orderBy('Tanggal', descending: true);
    _loadPembelianData();
  }
}
          ),
        ],
      ),
    );
  }

  Widget _buildDataTables() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Nama Barang")),
                  DataColumn(label: Text("Jumlah")),
                  DataColumn(label: Text("Harga per Unit")),
                  DataColumn(label: Text("Tipe")),
                  DataColumn(label: Text("Tanggal")),
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
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTotalSection(),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total Persediaan (P.Awal + Pembelian)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Nama Barang")),
                    DataColumn(label: Text("Tipe")),
                    DataColumn(label: Text("P.Awal")),
                    DataColumn(label: Text("Pembelian")),
                    DataColumn(label: Text("Total")),
                    DataColumn(label: Text("Satuan")),
                  ],
                  rows: _combinedData.entries.map((entry) {
                    final data = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(data["name"] ?? "")),
                      DataCell(Text(data["tipe"] ?? "")),
                      DataCell(Text(data["persAwal"].toString())),
                      DataCell(Text(data["pembelian"].toString())),
                      DataCell(Text(data["total"].toString())),
                      DataCell(Text(data["satuan"] ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unitController.dispose();
    _priceController.dispose();
    _typeController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
  
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/service/database.dart';
import 'package:random_string/random_string.dart';
import 'package:intl/intl.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';

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

  final TextEditingController _newNamaBarangController = TextEditingController();
final TextEditingController _newHargaController = TextEditingController();
final TextEditingController _newSatuanController = TextEditingController();
final TextEditingController _newJumlahController = TextEditingController();
final TextEditingController _newTipeController = TextEditingController();
final TextEditingController _newTanggalController = TextEditingController();
String _newSelectedUnit = 'Pcs';
bool _newIsOtherSelected = false;
DateTime _newSelectedDate = DateTime.now();
final List<String> _newUnits = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];

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

      await _db.collection("Users")
          .doc(userId)
          .collection("Pembelian")
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

      // Tambah notifikasi
      await addPembelianNotification(
        namaBarang: barangData['Name'],
        jumlah: int.parse(_unitController.text),
        satuan: barangData["Satuan"],
        type: _isDifferentType ? _typeController.text : barangData["Tipe"],
      );

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Pembelian',
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputCard(),
                  const SizedBox(height: 24),
                  _buildMonthFilterCard(),
                  const SizedBox(height: 24),
                  if (_isLoadingPembelian)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
                      ),
                    )
                  else
                    _buildDataTables(),
                ],
              ),
            ),
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
        // Header section with title and new item button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Input Pembelian',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF080C67),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _newTanggalController.text = DateFormat('yyyy-MM-dd').format(_newSelectedDate);
                _showAddNewItemDialog();
              },
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF080C67),
              ),
              label: Text(
                'Tambah Barang Baru',
                style: TextStyle(
                  color: Color(0xFF080C67),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFEEF2FF),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // Informative text about options
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilihan Pembelian:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
              SizedBox(height: 8),
              _buildInfoItem(
                '1. Barang yang sudah ada',
                'Pilih dari daftar barang yang tersedia di bawah',
              ),
              SizedBox(height: 4),
              _buildInfoItem(
                '2. Barang dengan tipe berbeda',
                'Centang "Tipe berbeda" untuk mengubah tipe dan harga',
              ),
              SizedBox(height: 4),
              _buildInfoItem(
                '3. Barang baru',
                'Klik tombol "Tambah Barang Baru" di atas',
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // Main input form
        Text(
          'Detail Pembelian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF080C67),
          ),
        ),
        SizedBox(height: 16),
        
        // Existing item selection
        _buildDropdownField(
          label: 'Pilih Barang yang Tersedia',
          icon: Icons.inventory_2_rounded,
          child: DropdownButtonFormField<String>(
            value: _selectedBarang,
            hint: Text('Pilih barang yang sudah ada'),
            items: _barangCache.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  '${entry.value["Name"]} (${entry.value["Tipe"] ?? "Default"})',
                ),
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
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        SizedBox(height: 16),
        
        _buildInputField(
          label: 'Jumlah Unit',
          controller: _unitController,
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          hintText: 'Masukkan jumlah yang dibeli',
        ),
        SizedBox(height: 16),

        // Different type option
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Color(0xFF080C67),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CheckboxListTile(
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
                      title: Text(
                        "Tipe barang berbeda",
                        style: TextStyle(
                          color: Color(0xFF080C67),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "Centang jika membeli barang dengan tipe atau harga berbeda",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Conditional fields for different type
        if (_isDifferentType) ...[
          _buildInputField(
            label: 'Tipe Barang Baru',
            controller: _typeController,
            icon: Icons.category_rounded,
            hintText: 'Masukkan tipe barang yang berbeda',
          ),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Harga per Unit Baru',
            controller: _priceController,
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            hintText: 'Masukkan harga baru',
          ),
        ] else
          _buildInputField(
            label: 'Harga per Unit',
            controller: _priceController,
            icon: Icons.payments_rounded,
            readOnly: true,
            hintText: '(mengikuti harga barang yang dipilih)',
          ),
        SizedBox(height: 16),
        
        _buildInputField(
          label: 'Tanggal Pembelian',
          controller: _tanggalController,
          icon: Icons.calendar_today_rounded,
          readOnly: true,
          onTap: () => _selectDate(context),
          hintText: 'Pilih tanggal pembelian',
        ),
        SizedBox(height: 32),

        // Submit button
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
              onTap: _isSubmitting ? null : _tambahBarang,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Simpan Pembelian',
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

// Helper method for building info items
Widget _buildInfoItem(String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  void _showAddNewItemDialog() {
  // Reset all controllers and selections
  _newNamaBarangController.clear();
  _newHargaController.clear();
  _newSatuanController.clear();
  _newJumlahController.clear();
  _newTipeController.clear();
  _newSelectedUnit = 'Pcs';
  _newIsOtherSelected = false;
  _newTanggalController.text = DateFormat('yyyy-MM-dd').format(_newSelectedDate);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          'Tambah Barang Baru',
          style: TextStyle(
            color: Color(0xFF080C67),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInputField(
                label: 'Nama Barang',
                controller: _newNamaBarangController,
                icon: Icons.inventory_2_rounded,
              ),
              SizedBox(height: 16),
              _buildDialogInputField(
                label: 'Tipe',
                controller: _newTipeController,
                icon: Icons.category_rounded,
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satuan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF080C67),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.straighten_rounded, color: Color(0xFF080C67)),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _newSelectedUnit,
                              items: _newUnits.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _newSelectedUnit = value!;
                                  _newIsOtherSelected = value == 'Lainnya';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_newIsOtherSelected) ...[
                SizedBox(height: 16),
                _buildDialogInputField(
                  label: 'Satuan Custom',
                  controller: _newSatuanController,
                  icon: Icons.edit_rounded,
                ),
              ],
              SizedBox(height: 16),
              _buildDialogInputField(
                label: 'Jumlah',
                controller: _newJumlahController,
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildDialogInputField(
                label: 'Harga per Unit',
                controller: _newHargaController,
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildDialogInputField(
                label: 'Tanggal',
                controller: _newTanggalController,
                icon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: () => _selectNewDate(context, setState),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveNewItem(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF080C67),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

//database
Future<void> _selectNewDate(BuildContext context, StateSetter setState) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _newSelectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  if (picked != null && picked != _newSelectedDate) {
    setState(() {
      _newSelectedDate = picked;
      _newTanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }
}

Widget _buildDialogInputField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  TextInputType? keyboardType,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF080C67),
        ),
      ),
      SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF080C67), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    ],
  );
}

Future<void> _saveNewItem(BuildContext context) async {
  // Validate all required fields
  if (_newNamaBarangController.text.isEmpty ||
      _newTipeController.text.isEmpty ||
      _newJumlahController.text.isEmpty ||
      _newHargaController.text.isEmpty ||
      _newTanggalController.text.isEmpty ||
      (_newIsOtherSelected && _newSatuanController.text.isEmpty)) {
    _showError("Semua field harus diisi");
    return;
  }

  try {
    final String barangId = randomAlphaNumeric(10);
    final userId = DatabaseMethods().currentUserId;
    
    // Create a barang reference but with isFromPembelian flag
    final Map<String, dynamic> barangData = {
      "Name": _newNamaBarangController.text,
      "Tipe": _newTipeController.text,
      "Satuan": _newIsOtherSelected ? _newSatuanController.text : _newSelectedUnit,
      "Price": int.parse(_newHargaController.text),
      "Jumlah": 0,  // Initial stock is 0
      "Id": barangId,
      "Tanggal": _newTanggalController.text,
      "isFromPembelian": true,  // Add this flag
      "userId": userId,
      "createdAt": FieldValue.serverTimestamp(),
    };

    // Add to Barang collection with the flag
    await _db.collection("Users")
        .doc(userId)
        .collection("Barang")
        .doc(barangId)
        .set(barangData);
    
    // Create the pembelian entry
    final Map<String, dynamic> pembelianData = {
      "BarangId": barangId,
      "Name": _newNamaBarangController.text,
      "Jumlah": int.parse(_newJumlahController.text),
      "Price": int.parse(_newHargaController.text),
      "Type": _newTipeController.text,
      "Satuan": _newIsOtherSelected ? _newSatuanController.text : _newSelectedUnit,
      "Timestamp": FieldValue.serverTimestamp(),
      "Tanggal": _newTanggalController.text,
    };

    // Add to Pembelian collection
    await _db.collection("Users")
        .doc(userId)
        .collection("Pembelian")
        .add(pembelianData);

    // Update PersediaanTotal
    await _db.collection("Users")
        .doc(userId)
        .collection("PersediaanTotal")
        .doc(barangId)
        .set({
          'Name': _newNamaBarangController.text,
          'Tipe': _newTipeController.text,
          'Jumlah': int.parse(_newJumlahController.text),
          'Price': int.parse(_newHargaController.text),
          'Satuan': _newIsOtherSelected ? _newSatuanController.text : _newSelectedUnit,
          'Tanggal': _newTanggalController.text,
          'LastUpdated': FieldValue.serverTimestamp(),
        });

    // Add to Riwayat
    await _db.collection("Users")
        .doc(userId)
        .collection("Riwayat")
        .add({
          'type': 'Pembelian',
          'name': _newNamaBarangController.text,
          'tipe': _newTipeController.text,
          'jumlah': int.parse(_newJumlahController.text),
          'price': int.parse(_newHargaController.text),
          'satuan': _newIsOtherSelected ? _newSatuanController.text : _newSelectedUnit,
          'tanggal': _newTanggalController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
    
    Navigator.pop(context);
    _showSuccess("Pembelian barang baru berhasil ditambahkan");
    
    // Refresh the data
    setState(() {
      _isLoadingBarang = true;
      _isLoadingPembelian = true;
    });
    await Future.wait([
      _loadBarangData(),
      _loadPembelianData(),
    ]);
    
  } catch (e) {
    print('Error saving new item: $e');
    _showError("Gagal menambahkan pembelian: $e");
  }
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

  Widget _buildMonthFilterCard() {
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
                      child: Text(
                        DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
                      ),
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

  Widget _buildDataTables() {
    return Column(
      children: [
        _buildDataTable(),
        SizedBox(height: 24),
        _buildTotalSection(),
      ],
    );
  }

  Widget _buildDataTable() {
    return Container(
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
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Data Pembelian",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF080C67),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Color(0xFFEEF2FF)),
              headingTextStyle: TextStyle(
                color: Color(0xFF080C67),
                fontWeight: FontWeight.w600,
              ),
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
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
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
            "Total Persediaan (P.Awal + Pembelian)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Color(0xFFEEF2FF)),
              headingTextStyle: TextStyle(
                color: Color(0xFF080C67),
                fontWeight: FontWeight.w600,
              ),
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
        ],
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
    String? hintText,
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
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
  @override
  void dispose() {
    _unitController.dispose();
    _priceController.dispose();
    _typeController.dispose();
    _tanggalController.dispose();
    _newNamaBarangController.dispose();
  _newHargaController.dispose();
  _newSatuanController.dispose();
  _newJumlahController.dispose();
  _newTipeController.dispose();
  _newTanggalController.dispose();
    super.dispose();
  }
  
  
}
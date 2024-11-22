import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:hpp_project/service/database.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';

class InputPembelianPage extends StatefulWidget {
  const InputPembelianPage({super.key});

  @override
  State<InputPembelianPage> createState() => _InputPembelianPageState();
}

class _InputPembelianPageState extends State<InputPembelianPage> {
  // Controllers
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _satuanCustomController = TextEditingController();
  final TextEditingController _tipeCustomController = TextEditingController();
  
  
  // Variables
  String _selectedUnit = 'Pcs';
  bool _isOtherSelected = false;
  DateTime _selectedDate = DateTime.now();
  final List<String> _units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];
  bool _isLoading = false;
  bool _isLoadingData = true;
  List<DocumentSnapshot> _existingItems = [];
  DocumentSnapshot? _selectedItem;
  bool _isNewItem = true;
  String _selectedType = 'Makanan';
  bool _isOtherTypeSelected = false;
  final List<String> _types = ['Makanan', 'Minuman', 'Sepatu', 'Pakaian', 'Alat Tulis', 'Elektronik', 'Kosmetik', 'Lainnya'];
  

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadExistingItems();
  }

  Future<void> _loadExistingItems() async {
    try {
      final userId = DatabaseMethods().currentUserId;
      final snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .get();
      
      setState(() {
        _existingItems = snapshot.docs;
        _isLoadingData = false;
      });
    } catch (e) {
      _showError("Gagal memuat data barang: $e");
      setState(() => _isLoadingData = false);
    }
  }

  void _resetForm() {
    _namaBarangController.clear();
    _hargaController.clear();
    _jumlahController.clear();
    _tipeController.clear();
    _satuanCustomController.clear();
    _tipeCustomController.clear();
    setState(() {
      _selectedUnit = 'Pcs';
      _isOtherSelected = false;
      _selectedType = 'Makanan';
      _isOtherTypeSelected = false;
      _selectedItem = null;
    });
  }
void _onExistingItemSelected(DocumentSnapshot? item) {
    if (item == null) {
      _resetForm();
      return;
    }

    try {
      final data = item.data() as Map<String, dynamic>;
      setState(() {
        _selectedItem = item;
        _namaBarangController.text = data['Name'] ?? '';
        
        // Set tipe from existing data
        final existingType = data['Tipe'] ?? data['Type'] ?? 'Makanan';
        _selectedType = existingType;
        
        // Set satuan from existing data
        final existingSatuan = data['Satuan'] ?? 'Pcs';
        _selectedUnit = existingSatuan;
        
        _hargaController.text = data['Price']?.toString() ?? '0';
        _jumlahController.clear();
      });
    } catch (e) {
      print('Error selecting item: $e');
      _showError('Terjadi kesalahan saat memilih barang');
    }
  }

 Future<void> _saveItem() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = DatabaseMethods().currentUserId;
      final now = DateTime.now();
      
      if (!_isNewItem && _selectedItem != null) {
        // Untuk barang yang sudah ada
        final existingData = _selectedItem!.data() as Map<String, dynamic>;
        
        // PERUBAHAN: Tidak perlu update jumlah di Barang/Persediaan Awal
        // Hanya buat record pembelian baru
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(userId)
            .collection("Pembelian")
            .add({
          "BarangId": _selectedItem!.id,
          "Name": existingData['Name'],
          "Jumlah": int.parse(_jumlahController.text),
          "Price": existingData['Price'],
          "Type": existingData['Tipe'] ?? existingData['Type'],
          "Satuan": existingData['Satuan'],
          "Tanggal": _tanggalController.text,
          "CreatedAt": FieldValue.serverTimestamp(),
        });

      } else {
        // Untuk barang baru
        final String barangId = randomAlphaNumeric(10);
        final String finalType = _isOtherTypeSelected ? _tipeCustomController.text : _selectedType;
        final String finalSatuan = _isOtherSelected ? _satuanCustomController.text : _selectedUnit;
        
        // Create new Barang
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(userId)
            .collection("Barang")
            .doc(barangId)
            .set({
          "Name": _namaBarangController.text,
          "Tipe": finalType,
          "Satuan": finalSatuan,
          "Price": int.parse(_hargaController.text),
          "Jumlah": int.parse(_jumlahController.text),
          "Tanggal": _tanggalController.text,
          "CreatedAt": FieldValue.serverTimestamp(),
        });

        // Create Pembelian record
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(userId)
            .collection("Pembelian")
            .add({
          "BarangId": barangId,
          "Name": _namaBarangController.text,
          "Jumlah": int.parse(_jumlahController.text),
          "Price": int.parse(_hargaController.text),
          "Type": finalType,
          "Satuan": finalSatuan,
          "Tanggal": _tanggalController.text,
          "CreatedAt": FieldValue.serverTimestamp(),
        });
      }

      await addPembelianNotification(
        namaBarang: _namaBarangController.text,
        jumlah: int.parse(_jumlahController.text),
        satuan: _isOtherSelected ? _satuanCustomController.text : _selectedUnit,
        type: _selectedType,
      );

      _showSuccess("Pembelian berhasil ditambahkan");
      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving purchase: $e");
      _showError("Gagal menyimpan pembelian: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
Widget _buildTypeDropdown() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tipe Barang',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFF080C67),
        ),
      ),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
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
            Icon(
              Icons.category_rounded,
              color: Color(0xFF080C67),
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                  items: _types.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                      _isOtherTypeSelected = newValue == 'Lainnya';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      if (_isOtherTypeSelected)
        _buildInputField(
          label: 'Tipe Lainnya',
          controller: _tipeCustomController,
          hintText: 'Masukkan tipe custom',
          icon: Icons.edit_rounded,
        ),
    ],
  );
}
  
  Widget _buildDropdownBarang() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<DocumentSnapshot>(
        isExpanded: true,
        hint: Text('Pilih barang yang tersedia'),
        value: _selectedItem,
        items: _existingItems.map((item) {
          final data = item.data() as Map<String, dynamic>;
          return DropdownMenuItem<DocumentSnapshot>(
            value: item,
            child: Text(
              "${data['Name'] ?? 'Unnamed'} - ${data['Tipe'] ?? 'No Type'} (${data['Satuan'] ?? 'No Unit'})",
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) => _onExistingItemSelected(value),
      ),
    ),
  );
}


  Widget _buildInputSection() {
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
          // Item Selection Section
          Text(
            'Pilih Jenis Input',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Barang Baru'),
                  value: true,
                  groupValue: _isNewItem,
                  onChanged: (value) {
                    setState(() {
                      _isNewItem = true;
                      _resetForm();
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Barang Ada'),
                  value: false,
                  groupValue: _isNewItem,
                  onChanged: (value) {
                    setState(() {
                      _isNewItem = false;
                      _resetForm();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Existing Items Dropdown (shown only when selecting existing item)
          if (!_isNewItem) ...[
            Text(
              'Pilih Barang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF080C67),
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DocumentSnapshot>(
                  isExpanded: true,
                  hint: Text('Pilih barang yang tersedia'),
                  value: _selectedItem,
                  items: _existingItems.map((item) {
                    final data = item.data() as Map<String, dynamic>;
                    return DropdownMenuItem<DocumentSnapshot>(
                      value: item,
                      child: Text(
                        "${data['Name']} - ${data['Tipe']} (${data['Satuan']})",
                      ),
                    );
                  }).toList(),
                  onChanged: _onExistingItemSelected,
                ),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Form Fields
          _buildInputField(
            label: 'Nama Barang',
            controller: _namaBarangController,
            icon: Icons.inventory_2_rounded,
            readOnly: !_isNewItem,
          ),
          SizedBox(height: 16),
          if (_isNewItem) ...[
  _buildTypeDropdown(),
] else ...[
  _buildInputField(
    label: 'Tipe Barang',
    controller: TextEditingController(text: _selectedType),
    icon: Icons.category_rounded,
    readOnly: true,
  ),
],
          SizedBox(height: 16),
          if (_isNewItem) ...[
            // Satuan dropdown for new items
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satuan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF080C67),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedUnit,
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                          _isOtherSelected = value == 'Lainnya';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_isOtherSelected) ...[
              SizedBox(height: 16),
              _buildInputField(
                label: 'Satuan Custom',
                controller: _satuanCustomController,
                icon: Icons.edit_rounded,
              ),
            ],
          ] else ...[
            // Display readonly satuan for existing items
            _buildInputField(
              label: 'Satuan',
              controller: TextEditingController(text: _selectedUnit),
              icon: Icons.straighten_rounded,
              readOnly: true,
            ),
          ],
          SizedBox(height: 16),
          _buildInputField(
            label: 'Jumlah',
            controller: _jumlahController,
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Harga per Unit',
            controller: _hargaController,
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            readOnly: !_isNewItem,
          ),
          SizedBox(height: 16),
          _buildInputField(
            label: 'Tanggal',
            controller: _tanggalController,
            icon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: _selectDate,
          ),
          SizedBox(height: 32),
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
                onTap: _isLoading ? null : _saveItem,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white),
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
  Future<void> _selectDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF080C67),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null && picked != _selectedDate) {
    setState(() {
      _selectedDate = picked;
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Input Pembelian',
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
      ),body: _isLoadingData 
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                ],
              ),
            ),
    );
  }
// Ubah method _buildInputField untuk menambahkan parameter hintText:
Widget _buildInputField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  TextInputType? keyboardType,
  bool readOnly = false,
  VoidCallback? onTap,
  String? hintText, // Tambah parameter ini
}) {
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
          color: readOnly ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: readOnly ? Colors.grey[700] : Colors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF080C67), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hintText, // Tambah ini
            hintStyle: TextStyle( // Opsional: tambah style untuk hint
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      ),
    ],
  );
}
  bool _validateInput() {
    if (_jumlahController.text.isEmpty || _tanggalController.text.isEmpty) {
      _showError("Jumlah dan tanggal harus diisi");
      return false;
    }

    if (_isNewItem) {
  if (_namaBarangController.text.isEmpty ||
      _hargaController.text.isEmpty ||
      (_isOtherTypeSelected && _tipeCustomController.text.isEmpty) || // Tambah ini
      (_isOtherSelected && _satuanCustomController.text.isEmpty)) {
    _showError("Semua field harus diisi untuk barang baru");
    return false;
  }
} else if (_selectedItem == null) {
      _showError("Silakan pilih barang yang tersedia");
      return false;
    }

    return true;
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    _tipeController.dispose();
    _tanggalController.dispose();
    _satuanCustomController.dispose();
     _tipeCustomController.dispose();
  super.dispose();
  }
}
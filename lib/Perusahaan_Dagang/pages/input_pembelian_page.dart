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
  final TextEditingController _satuanCustomController = TextEditingController();
  final TextEditingController _tipeCustomController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  
  // Variables
  String _selectedUnit = 'Pcs';
  bool _isOtherSelected = false;
  DateTime _selectedDate = DateTime.now();
  final List<String> _units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];
  bool _isLoading = false;
  String _selectedType = 'Makanan';
  bool _isOtherTypeSelected = false;
  final List<String> _types = ['Makanan', 'Minuman', 'Sepatu', 'Pakaian', 'Alat Tulis', 'Elektronik', 'Kosmetik', 'Lainnya'];
  
  // AutoComplete suggestions
  List<Map<String, dynamic>> _existingItems = [];
  bool _isExistingItem = false;
  String? _selectedBarangId;

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
        _existingItems = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['Name'],
            'tipe': data['Tipe'],
            'satuan': data['Satuan'],
            'price': data['Price'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading existing items: $e");
      _showError("Gagal memuat data barang: $e");
    }
  }

  void _onExistingItemSelected(Map<String, dynamic> item) {
    setState(() {
      _isExistingItem = true;
      _selectedBarangId = item['id'];
      _namaBarangController.text = item['name'];
      _selectedType = item['tipe'];
      _selectedUnit = item['satuan'];
      _hargaController.text = item['price'].toString();
    });
  }

  Future<void> _saveItem() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = DatabaseMethods().currentUserId;
      final String finalType = _isOtherTypeSelected ? _tipeCustomController.text : _selectedType;
      final String finalSatuan = _isOtherSelected ? _satuanCustomController.text : _selectedUnit;

      String barangId;
      if (_isExistingItem && _selectedBarangId != null) {
        // Use existing barang ID
        barangId = _selectedBarangId!;
        
        // Update the price if it has changed
        if (int.parse(_hargaController.text) != _existingItems
            .firstWhere((item) => item['id'] == barangId)['price']) {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .collection("Barang")
              .doc(barangId)
              .update({
            "Price": int.parse(_hargaController.text),
            "LastUpdated": FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Check for existing item with same name and type
        QuerySnapshot existing = await FirebaseFirestore.instance
            .collection("Users")
            .doc(userId)
            .collection("Barang")
            .where("Name", isEqualTo: _namaBarangController.text)
            .where("Tipe", isEqualTo: finalType)
            .get();

        if (existing.docs.isNotEmpty) {
          barangId = existing.docs.first.id;
          // Update existing barang with new price
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .collection("Barang")
              .doc(barangId)
              .update({
            "Price": int.parse(_hargaController.text),
            "LastUpdated": FieldValue.serverTimestamp(),
          });
        } else {
          // Create new barang
          barangId = randomAlphaNumeric(10);
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
        }
      }

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

      // Add notification
      await addPembelianNotification(
        namaBarang: _namaBarangController.text,
        jumlah: int.parse(_jumlahController.text),
        satuan: finalSatuan,
        type: finalType,
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

  bool _validateInput() {
    if (_namaBarangController.text.isEmpty ||
        _jumlahController.text.isEmpty ||
        _hargaController.text.isEmpty ||
        _tanggalController.text.isEmpty) {
      _showError("Semua field harus diisi");
      return false;
    }

    if (_isOtherTypeSelected && _tipeCustomController.text.isEmpty) {
      _showError("Tipe custom harus diisi");
      return false;
    }

    if (_isOtherSelected && _satuanCustomController.text.isEmpty) {
      _showError("Satuan custom harus diisi");
      return false;
    }

    return true;
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
          Text(
            'Input Pembelian',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(height: 24),

          // Autocomplete for existing items
          _buildAutoComplete(),
          SizedBox(height: 16),

          _buildInputField(
            label: 'Nama Barang',
            controller: _namaBarangController,
            icon: Icons.inventory_2_rounded,
          ),
          SizedBox(height: 16),

          _buildTypeDropdown(),
          SizedBox(height: 16),

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

  Widget _buildAutoComplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cari Barang Yang Sudah Ada',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF080C67),
          ),
        ),
        SizedBox(height: 8),
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            return _existingItems.where((item) {
              return item['name'].toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          displayStringForOption: (option) => "${option['name']} - ${option['tipe']} (${option['satuan']})",
          onSelected: _onExistingItemSelected,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                focusNode: focusNode,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF080C67),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: 'Ketik untuk mencari barang yang sudah ada',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Barang',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
        if (_isOtherTypeSelected) ...[
          SizedBox(height: 16),
          _buildInputField(
            label: 'Tipe Custom',
            controller: _tipeCustomController,
            icon: Icons.edit_rounded,
            hintText: 'Masukkan tipe custom',
          ),
        ],
      ],
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
    FocusNode? focusNode,
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
            focusNode: focusNode,
            style: TextStyle(
              color: readOnly ? Colors.grey[700] : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF080C67), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
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
            ],
          ),
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            ],
          ),
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
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
          ),
        ),
      ),
      body: SingleChildScrollView(
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
  
  @override
  void dispose() {
    _namaBarangController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    _satuanCustomController.dispose();
    _tipeCustomController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
}
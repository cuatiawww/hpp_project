import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';
import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';

class InputPersAwal extends StatefulWidget {
  const InputPersAwal({super.key});

  @override
  State<InputPersAwal> createState() => _InputPersAwalState();
}


class _InputPersAwalState extends State<InputPersAwal> {
  final _formKeyPersAwal = GlobalKey<FormState>();
  
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _satuanController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _tipeCustomController = TextEditingController();

  String _selectedUnit = 'Pcs';
  final List<String> _units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];
  bool _isOtherSelected = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _selectedType = 'Makanan';
  bool _isOtherTypeSelected = false;
  final List<String> _types = ['Makanan', 'Minuman', 'Sepatu', 'Pakaian', 'Alat Tulis', 'Elektronik', 'Kosmetik', 'Lainnya'];
  

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
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

  Widget _buildInputField({
  required String label,
  required TextEditingController controller,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  bool readOnly = false,
  VoidCallback? onTap,
  String? hintText,
  IconData? icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
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
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator ?? (value) {
            if (value == null || value.isEmpty) {
              return 'Field ini harus diisi';
            }
            return null;
          },
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
      SizedBox(height: 16),
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

 Widget _buildUnitDropdown() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Satuan',
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
              Icons.straighten_rounded,
              color: Color(0xFF080C67),
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                  items: _units.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUnit = newValue!;
                      _isOtherSelected = newValue == 'Lainnya';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      if (_isOtherSelected)
        _buildInputField(
          label: 'Satuan Lainnya',
          controller: _satuanController,
          hintText: 'Masukkan satuan custom',
          icon: Icons.edit_rounded,
        ),
    ],
  );
}

  //DATABASES
  Future<void> _submitForm() async {
  if (!_formKeyPersAwal.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final String id = randomAlphaNumeric(10);
    final Map<String, dynamic> barangInfoMap = {
      "Name": _namaBarangController.text,
      "Tipe": _isOtherTypeSelected ? _tipeCustomController.text : _selectedType,
      "Satuan": _isOtherSelected ? _satuanController.text : _selectedUnit,
      "Jumlah": int.parse(_jumlahController.text),
      "Price": int.parse(_hargaController.text),
      "Id": id,
      "Tanggal": _tanggalController.text,
    };

      await DatabaseMethods().addBarang(barangInfoMap, id);

      // Menambahkan notifikasi
        await addNotification(
  title: 'Persediaan Awal Baru',
  message: 'Menambahkan ${_namaBarangController.text} sebanyak ${_jumlahController.text} ' +
          '${_isOtherSelected ? _satuanController.text : _selectedUnit} dengan tipe ' +
          '${_isOtherTypeSelected ? _tipeCustomController.text : _selectedType}',
);
      
      _showSuccessMessage("Data berhasil ditambahkan");
      _resetForm();
    } catch (e) {
      _showErrorMessage("Gagal menambahkan data: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
}
  // Setelah _submitForm(), modifikasi bagian _showSuccessMessage dan _showErrorMessage

void _showSuccessMessage(String message) {
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

void _showErrorMessage(String message) {
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

  void _resetForm() {
    _namaBarangController.clear();
    _hargaController.clear();
    _satuanController.clear();
    _jumlahController.clear();
    _tipeController.clear();
    _selectedUnit = 'Pcs';
    _isOtherSelected = false;
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _selectedType = 'Makanan';
  _isOtherTypeSelected = false;
  _tipeCustomController.clear();
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Input Persediaan Awal',
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
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Form(
        key: _formKeyPersAwal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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
                    _buildInputField(
                      label: 'Nama Barang',
                      controller: _namaBarangController,
                      hintText: 'Masukkan nama barang',
                      icon: Icons.inventory_2_rounded,
                    ),
                    _buildTypeDropdown(),
                    _buildUnitDropdown(),
                    _buildInputField(
                      label: 'Jumlah',
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      hintText: 'Masukkan jumlah',
                      icon: Icons.numbers_rounded,
                    ),
                    _buildInputField(
                      label: 'Harga',
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      hintText: 'Masukkan harga per unit',
                      icon: Icons.payments_rounded,
                    ),
                    _buildInputField(
                      label: 'Tanggal',
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      icon: Icons.calendar_today_rounded,
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
                          onTap: _isLoading ? null : _submitForm,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
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
                                        'Tambah Barang',
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
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  @override
  void dispose() {
    _namaBarangController.dispose();
    _hargaController.dispose();
    _satuanController.dispose();
    _jumlahController.dispose();
    _tipeController.dispose();
    _tanggalController.dispose();
     _tipeCustomController.dispose();
  super.dispose();
  }
}
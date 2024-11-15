import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _satuanController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  String _selectedUnit = 'Pcs';
  final List<String> _units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];
  bool _isOtherSelected = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String id = randomAlphaNumeric(10);
      final Map<String, dynamic> barangInfoMap = {
        "Name": _namaBarangController.text,
        "Tipe": _tipeController.text,
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
          message: 'Menambahkan ${_namaBarangController.text} sebanyak ${_jumlahController.text} ${_satuanController.text} dengan tipe ${_tipeController.text}',
        );
      
      _showSuccessMessage("Data berhasil ditambahkan");
      _resetForm();
    } catch (e) {
      _showErrorMessage("Gagal menambahkan data: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
}
  void _showSuccessMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
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
        key: _formKey,
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
                    _buildInputField(
                      label: 'Tipe',
                      controller: _tipeController,
                      hintText: 'Masukkan tipe barang',
                      icon: Icons.category_rounded,
                    ),
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
                      icon: Icons.attach_money_rounded,
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
    super.dispose();
  }
}
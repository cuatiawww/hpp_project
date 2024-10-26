import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    Widget? suffix,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
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
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Satuan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedUnit,
              isExpanded: true,
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
        const SizedBox(height: 16),
        if (_isOtherSelected) 
          _buildInputField(
            label: 'Satuan Lainnya',
            controller: _satuanController,
            hintText: 'Masukkan satuan custom',
          ),
      ],
    );
  }

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
      
      _showSuccessMessage("Data berhasil ditambahkan");
      _resetForm();
    } catch (e) {
      _showErrorMessage("Gagal menambahkan data: $e");
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
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: "Input Pers. Awal",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white24,
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          label: 'Nama Barang',
                          controller: _namaBarangController,
                          hintText: 'Masukkan nama barang',
                        ),
                        _buildInputField(
                          label: 'Tipe',
                          controller: _tipeController,
                          hintText: 'Masukkan tipe barang',
                        ),
                        _buildUnitDropdown(),
                        _buildInputField(
                          label: 'Jumlah',
                          controller: _jumlahController,
                          keyboardType: TextInputType.number,
                          hintText: 'Masukkan jumlah',
                        ),
                        _buildInputField(
                          label: 'Harga',
                          controller: _hargaController,
                          keyboardType: TextInputType.number,
                          hintText: 'Masukkan harga per unit',
                        ),
                        _buildInputField(
                          label: 'Tanggal',
                          controller: _tanggalController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          suffix: const Icon(Icons.calendar_today),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Tambah Barang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
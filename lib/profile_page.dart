import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isSaving = false;
  int _selectedIndex = 2; // Index untuk tab Akun
  final authC = Get.find<AuthController>();
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  late final DataPribadiController dataPribadiC;
  late final DataUsahaController dataUsahaC;

  final namaLengkapController = TextEditingController();
  final npwpController = TextEditingController();
  final tanggalLahirController = TextEditingController();
  final jenisKelaminController = TextEditingController();
  final namaUsahaController = TextEditingController();
  final tipeUsahaController = TextEditingController();
  final nomorTeleponController = TextEditingController();

  final List<String> jenisKelaminOptions = ['Laki-laki', 'Perempuan'];
  final npwpFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  String formatNPWP(String text) {
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 15) text = text.substring(0, 15);
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 4 || i == 7 || i == 8 || i == 11) {
        if (i == 8) {
          buffer.write('-');
        } else {
          buffer.write('.');
        }
      }
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    dataPribadiC = Get.put(DataPribadiController(uid: currentUserUid));
    dataUsahaC = Get.put(DataUsahaController(uid: currentUserUid));

    npwpController.addListener(() {
      final text = npwpController.text;
      if (text.isNotEmpty) {
        final formatted = formatNPWP(text);
        if (formatted != text) {
          npwpController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });

    loadUserData();
  }

  Future<void> loadUserData() async {
    await dataPribadiC.fetchDataPribadi(currentUserUid);
    await dataUsahaC.fetchDataUsaha(currentUserUid);

    setState(() {
      namaLengkapController.text = dataPribadiC.namaLengkap.value;
      npwpController.text = formatNPWP(dataPribadiC.npwp.value);
      tanggalLahirController.text = dataPribadiC.tanggalLahir.value;
      jenisKelaminController.text = dataPribadiC.jenisKelamin.value;
      namaUsahaController.text = dataUsahaC.namaUsaha.value;
      tipeUsahaController.text = dataUsahaC.tipeUsaha.value;
      nomorTeleponController.text = dataUsahaC.nomorTelepon.value;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalLahirController.text.isNotEmpty
          ? DateFormat('dd-MM-yyyy').parse(tanggalLahirController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        tanggalLahirController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        isSaving = true;
      });

      await dataPribadiC.updateDataPribadi(
        namaLengkapController.text,
        npwpController.text,
        tanggalLahirController.text,
        jenisKelaminController.text,
      );

      await dataUsahaC.updateDataUsaha(
        namaUsahaController.text,
        tipeUsahaController.text,
        nomorTeleponController.text,
      );

      await loadUserData();

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: ${e.toString()}'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditableTextField(String label, TextEditingController controller, {
    bool isDatePicker = false,
    bool isDropdown = false,
    bool isReadOnly = false,
    bool isNumeric = false,
    bool isNPWP = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: isDropdown ? 
        DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          items: jenisKelaminOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: isEditing ? (String? newValue) {
            setState(() {
              controller.text = newValue!;
            });
          } : null,
        )
        : TextFormField(
          controller: controller,
          enabled: isEditing && !isReadOnly,
          readOnly: isDatePicker || isReadOnly,
          keyboardType: (isNumeric || isNPWP) ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (isNumeric) FilteringTextInputFormatter.digitsOnly,
            if (isNPWP) npwpFormatter,
          ],
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            suffixIcon: isDatePicker && isEditing ? 
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ) : null,
            hintText: isNPWP ? 'XX.XXX.XXX.X-XXX.XXX' : null,
          ),
          onTap: isDatePicker && isEditing ? 
            () => _selectDate(context) : null,
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E23A7),
              Color(0xFF080C67),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Obx(() => Text(
                      dataPribadiC.namaLengkap.value,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: isSaving 
                        ? null
                        : () {
                          setState(() {
                            if (isEditing) {
                              _saveProfile();
                            } else {
                              isEditing = true;
                            }
                          });
                        },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF080C67),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                      ),
                      child: isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          isEditing ? 'Simpan' : 'Edit Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildEditableTextField('Nama Lengkap', namaLengkapController),
                  SizedBox(height: 16),
                  _buildEditableTextField('NPWP', npwpController, isNPWP: true),
                  SizedBox(height: 16),
                  _buildEditableTextField('Tanggal Lahir', tanggalLahirController, isDatePicker: true),
                  SizedBox(height: 16),
                  _buildEditableTextField('Jenis Kelamin', jenisKelaminController, isDropdown: true),
                  SizedBox(height: 24),
                  Text(
                    'Informasi Usaha',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildEditableTextField('Nama Usaha', namaUsahaController),
                  SizedBox(height: 16),
                  _buildEditableTextField('Tipe Usaha', tipeUsahaController, isReadOnly: true),
                  SizedBox(height: 16),
                  _buildEditableTextField('Nomor Telepon', nomorTeleponController, isNumeric: true),
                  SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => authC.logout(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 70, vertical: 12),
                      ),
                      child: Text('LOGOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(height: 20), // Tambahan padding bawah untuk bottom navbar
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }

  @override
  void dispose() {
    namaLengkapController.dispose();
    npwpController.dispose();
    tanggalLahirController.dispose();
    jenisKelaminController.dispose();
    namaUsahaController.dispose();
    tipeUsahaController.dispose();
    nomorTeleponController.dispose();
    super.dispose();
  }
}
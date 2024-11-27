import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';
import 'package:hpp_project/routes/routes.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isSaving = false;

  String? avatarBase64; // Menyimpan avatar Base64 pengguna
  final picker = ImagePicker(); // Untuk memilih gambar
  
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
    validateAndLoadAvatar();
    loadUserData();
  }

  // Validasi UID di Firestore dan memuat avatar
  Future<void> validateAndLoadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserUid)
        .get();

    if (userDoc.exists) {
      // Ambil avatar dari SharedPreferences
      final storedAvatar = prefs.getString('avatar_$currentUserUid');
      setState(() {
        avatarBase64 = storedAvatar; // Set avatar untuk ditampilkan
      });
    } else {
      // Jika UID tidak ditemukan, logout pengguna
      Get.offAllNamed(Routes.login);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('UID pengguna tidak valid!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Memuat data pengguna dari Firestore
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

  // Menyimpan avatar ke SharedPreferences
  Future<void> saveAvatar(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_$currentUserUid', base64Image);
    setState(() {
      avatarBase64 = base64Image;
    });
  }

  // Fungsi untuk memilih dan menyimpan avatar
  Future<void> _pickAndSaveAvatar() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      await saveAvatar(base64Image);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
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
@override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(height: 24),
                      // Profile Picture Section
                      GestureDetector(
                        onTap: isEditing ? _pickAndSaveAvatar : null,
                        child: Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: avatarBase64 != null
                                    ? MemoryImage(base64Decode(avatarBase64!))
                                    : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Color(0xFF080C67),
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Obx(() => Text(
                        dataPribadiC.namaLengkap.value,
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      SizedBox(height: 4),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildEditButton(),
                    ],
                  ),
                ),
                
                // Content Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Informasi Pribadi', Icons.person_rounded),
                      SizedBox(height: 16),
                      _buildContentCard([
                        _buildField('Nama Lengkap', namaLengkapController),
                        _buildDivider(),
                        _buildField('NPWP', npwpController, isNPWP: true),
                        _buildDivider(),
                        _buildField('Tanggal Lahir', tanggalLahirController, isDatePicker: true),
                        _buildDivider(),
                        _buildField('Jenis Kelamin', jenisKelaminController, isDropdown: true),
                      ]),
                      
                      SizedBox(height: 24),
                      _buildSectionHeader('Informasi Usaha', Icons.business_rounded),
                      SizedBox(height: 16),
                      _buildContentCard([
                        _buildField('Nama Usaha', namaUsahaController),
                        _buildDivider(),
                        _buildField('Tipe Usaha', tipeUsahaController, isReadOnly: true),
                        _buildDivider(),
                        _buildField('Nomor Telepon', nomorTeleponController, isNumeric: true),
                      ]),
                      
                      SizedBox(height: 32),
                      _buildLogoutButton(),
                      SizedBox(height: 32),
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

  Widget _buildEditButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isSaving ? null : () {
            setState(() {
              if (isEditing) {
                _saveProfile();
              } else {
                isEditing = true;
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEditing ? Icons.save_rounded : Icons.edit_rounded,
                  color: Color(0xFF080C67),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  isEditing ? 'Simpan' : 'Edit Profil',
                  style: TextStyle(
                    color: Color(0xFF080C67),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {
    bool isDatePicker = false,
    bool isDropdown = false,
    bool isReadOnly = false,
    bool isNumeric = false,
    bool isNPWP = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          if (isDropdown)
            _buildDropdown(controller)
          else
            _buildInput(controller, isDatePicker, isReadOnly, isNumeric, isNPWP),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    bool isDatePicker,
    bool isReadOnly,
    bool isNumeric,
    bool isNPWP,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: isEditing && !isReadOnly,
        readOnly: isDatePicker || isReadOnly,
        keyboardType: (isNumeric || isNPWP) ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumeric) FilteringTextInputFormatter.digitsOnly,
          if (isNPWP) npwpFormatter,
        ],
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: isDatePicker && isEditing
              ? IconButton(
                  icon: Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                  onPressed: () => _selectDate(context),
                )
              : null,
          hintText: isNPWP ? 'XX.XXX.XXX.X-XXX.XXX' : null,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        onTap: isDatePicker && isEditing ? () => _selectDate(context) : null,
      ),
    );
  }

  Widget _buildDropdown(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        dropdownColor: Color(0xFF080C67),
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
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
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.red,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => authC.logout(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Keluar',
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
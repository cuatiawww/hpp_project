import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/theme.dart';
import 'package:hpp_project/user_auth/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false; // Untuk melacak mode edit
  final authC = Get.find<AuthController>(); // Inisialisasi AuthController untuk mengakses fungsi logout

  // Controller untuk TextFormField
  final _nameController = TextEditingController(text: 'Zendaya Coleman');
  final _npwpController = TextEditingController(text: 'XXXXXXXXXXXXXXXXX');
  final _dobController = TextEditingController(text: '27-06-1997');
  final _genderController = TextEditingController(text: 'Perempuan');
  final _storeNameController = TextEditingController(text: 'Toko Agung');
  final _storeAddressController = TextEditingController(text: 'Azkhal Citayem Street');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                child: Text(
                  'Toko Agung',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Agung@surya.co.id',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing; // Toggle antara mode edit dan tidak
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: secondary, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 8), 
                  ),
                  child: Text(
                    isEditing ? 'Simpan' : 'Edit Akun', 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildEditableTextField('Nama Lengkap', _nameController),
              SizedBox(height: 16),
              _buildEditableTextField('NPWP', _npwpController),
              SizedBox(height: 16),
              _buildEditableTextField('Tanggal Lahir', _dobController),
              SizedBox(height: 16),
              _buildEditableTextField('Jenis Kelamin', _genderController),
              SizedBox(height: 24),
              Text(
                'Informasi Usaha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildEditableTextField('Nama Usaha', _storeNameController),
              SizedBox(height: 16),
              _buildEditableTextField('Alamat Usaha', _storeAddressController),
              SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () => authC.logout(), // Memanggil fungsi logout pada authController
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red, // Warna merah untuk tombol log out
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 42, vertical: 12),
                  ),
                  child: Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membuat TextField yang dapat diedit
  Widget _buildEditableTextField(String label, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: TextFormField(
        controller: controller,
        enabled: isEditing, // jika aktif maka bisa edit
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _npwpController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }
}

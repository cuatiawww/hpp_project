import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/home_page.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoScreen extends StatefulWidget {

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  // final _formKey = GlobalKey<FormState>();
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Get.arguments;  // Mengambil UID dari argument yang dikirim oleh AuthController
  }

  int currentStep = 0; // Step yang sedang aktif
  bool isCompleted = false; // Apakah semua step selesai

  // Key form
  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // Controller Step 1
  final TextEditingController namaLengkap = TextEditingController();
  final TextEditingController npwp = TextEditingController();
  final TextEditingController tanggalLahir = TextEditingController();
  String? jenisKelamin; // variabel untuk menyimpan nilai dropdown Gender

  // Controller Step 2
  final TextEditingController namaUsaha = TextEditingController();
  String? tipeUsaha; // variabel untuk menyimpan nilai dropdown CompanyType
  final TextEditingController nomorTelepon = TextEditingController();

  void dispose() {
    namaLengkap.dispose();
    npwp.dispose();
    tanggalLahir.dispose();
    namaUsaha.dispose();
    nomorTelepon.dispose();
    super.dispose();
  }

  // Format date untuk memastikan input tanggal valid
  final DateFormat dateFormatter = DateFormat('dd-MM-yyyy');

  // Fungsi untuk menampilkan DatePicker dan set value ke field
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      errorInvalidText: 'Pilih Tanggal yang Valid',
      errorFormatText: 'Format Tanggal Salah',
      fieldLabelText: 'Masukkan Tanggal',
      helpText: 'Pilih Tanggal',
      cancelText: 'Kembali',
      confirmText: 'Lanjut',
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        tanggalLahir.text = dateFormatter.format(pickedDate); // simpan tanggal terpilih
      });
    }
  }

  String getTitle() {
    if (currentStep == 0) {
      return 'INFORMASI PRIBADI';
    } else if (currentStep == 1) {
      return 'INFORMASI USAHA';
    } else {
      return '';
    }
  }
  
  Future<void> saveData() async {
    // Ambil UID pengguna dari Firebase Authentication
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) { // Cek jika UID ditemukan
      // Simpan data pribadi
      await FirebaseFirestore.instance.collection('Users').doc(uid).collection('PersonalData').doc('dataPribadi').set({
        'Nama Lengkap': namaLengkap.text,
        'NPWP': npwp.text,
        'Tanggal Lahir': tanggalLahir.text,
        'Jenis Kelamin': jenisKelamin,
      });

      // Simpan data usaha
      await FirebaseFirestore.instance.collection('Users').doc(uid).collection('BusinessData').doc('dataUsaha').set({
        'Nama Usaha': namaUsaha.text,
        'Tipe Usaha': tipeUsaha,
        'Nomor Telepon': nomorTelepon.text,
      });
      print('Data Berhasil Disimpan');
    } else {
      print('UID pengguna tidak ditemukan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTitle(),
          style: TextStyle(
            fontWeight: FontWeight.w600
          ),
        ),
        centerTitle: true,
      ),
      body: isCompleted
        ? HomePage()
        : Theme( // Untuk memberi style pada stepper
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Color(0xFF3E63F4),
          )
        ),
        child: Stepper(
          type: StepperType.horizontal,
          steps: getSteps(),
          currentStep: currentStep,
          onStepContinue: () {
            // Jika form di step saat ini tidak valid, return
            if (!formKeys[currentStep].currentState!.validate()) {
              return;
            }
            final isLastStep = currentStep == getSteps().length - 1;
            if (isLastStep) { // fungsi untuk mengecek apakah step terakhir
              saveData(); // Simpan data
              setState(() => isCompleted = true);
              print('Data Berhasi Disimpan');
              // TODO: Implement save data logic
            } else {
              // Lanjut ke step berikutnya
              setState(() => currentStep += 1);
            }
          },
          onStepTapped: (step) {
            setState(() {
              currentStep = step; // Pindah ke step yang di-tap
            });
          },
          onStepCancel: currentStep == 0 
              ? null
              : () => setState(() => currentStep -= 1),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final isLastStep = currentStep == getSteps().length - 1; // Cek apakah step terakhir
            return Container (
              margin: EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text( isLastStep ? 'Simpan' : 'Selanjutnya', 
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: details.onStepContinue,
                    ),
                  ),
                  SizedBox(width: 12),
                  if (currentStep != 0) // Untuk menyembunyikan button 'kembali pada step pertama'
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dark2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Kembali', 
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: details.onStepCancel,
                    ),
                  ),
                ],
              )
            );
          }
        ),
      )
    );
  }

  List<Step> getSteps() => [

    // STEP KE 1
    Step(
      state: currentStep > 0 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 0,
      title: Text(
        'Info Pribadi',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Lengkap',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            TextFormField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama Lengkap tidak boleh kosong';
                }
                return null;
              },
              controller: namaLengkap,
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
              hintText: 'Masukkan Nama Lengkap',
              ),
            ),
            SizedBox(height: 15),
            Text(
              'NPWP',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            TextFormField(
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              controller: npwp,
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
                hintText: 'Masukkan NPWP (opsional)',
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Tanggal Lahir',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: tanggalLahir,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan isi tanggal lahir anda';
                }
                try {
                  DateFormat('dd-MM-yyyy').parseStrict(value); // Validasi format tanggal
                } catch (e) {
                  return 'Masukkan format tanggal yang valid\n(contoh: DD-MM-YYYY)';
                }
                return null;
              },
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () => _selectDate(context), // Buka datepicker
                  icon: Icon(
                    Icons.calendar_month_outlined)
                ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
              hintText: 'Pilih Tanggal Lahir',
              ),
              onTap: () => _selectDate(context), // Buka datepicker saat field di-tap
            ),
            SizedBox(height: 15),
            Text(
              'Jenis Kelamin',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            DropdownButtonFormField<String>(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan pilih jenis kelamin anda';
                }
                return null;
              },
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
                hintText: 'Pilih Jenis Kelamin',
                ),
              value: jenisKelamin,
              items: <String>['Laki-laki', 'Perempuan'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  jenisKelamin = value; // simpan nilai dropdown
                });
              },
            ),
          ],
        ),
      ),
    ),
    
    // STEP KE 2
    Step(
      state: currentStep > 1 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 1,
      title: Text(
        'Info Usaha',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Perusahaan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: namaUsaha,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan masukkan nama usaha anda';
                }
                return null;
              },
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
                hintText: 'Masukkan Nama Perusahaan',
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Jenis Usaha',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            DropdownButtonFormField<String>(
               validator: (value) {
                if (value == null) {
                  return 'Silakan pilih jenis perusahaan anda';
                }
                return null;
              },
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
                hintText: 'Pilih Jenis Perusahaan'
              ),
              value: tipeUsaha,
              items: <String>['Perusahaan Dagang', 'Perusahaan Manufaktur'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  tipeUsaha = value; // simpan nilai dropdown
                });
              },
            ),
            SizedBox(height: 15),
            Text(
              'Nomor Telepon',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: nomorTelepon,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Masukkan nomor telepon yang valid\n(Contoh: 08123456789)';
                }
                return null;
              },
              decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              ),
                hintText: 'Masukkan Nomor Telepon',
              ),
            ),
          ],
        ),
      ),
    )
  ];
}

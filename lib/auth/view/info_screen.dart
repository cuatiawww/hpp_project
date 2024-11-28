import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';
import 'package:hpp_project/routes/routes.dart';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = Get.arguments; // Mengambil UID dari argument yang dikirim oleh AuthController
  }

  int currentStep = 0; // Step yang sedang aktif
  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // Controller Step 1
  final TextEditingController namaLengkap = TextEditingController();
  final TextEditingController npwp = TextEditingController();
  final TextEditingController tanggalLahir = TextEditingController();
  String? jenisKelamin;

  // Controller Step 2
  final TextEditingController namaUsaha = TextEditingController();
  String? tipeUsaha;
  final TextEditingController nomorTelepon = TextEditingController();

  @override
  void dispose() {
    namaLengkap.dispose();
    npwp.dispose();
    tanggalLahir.dispose();
    namaUsaha.dispose();
    nomorTelepon.dispose();
    super.dispose();
  }

  final DateFormat dateFormatter = DateFormat('dd-MM-yyyy');

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        tanggalLahir.text = dateFormatter.format(pickedDate);
      });
    }
  }

  Future<void> saveData() async {
  try {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Save personal data
        final personalRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('PersonalData')
            .doc('dataPribadi');
            
        transaction.set(personalRef, {
          'Nama Lengkap': namaLengkap.text,
          'NPWP': npwp.text,
          'Tanggal Lahir': tanggalLahir.text,
          'Jenis Kelamin': jenisKelamin,
        });

        // Save business data
        final businessRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('BusinessData')
            .doc('dataUsaha');
            
        transaction.set(businessRef, {
          'Nama Usaha': namaUsaha.text,
          'Tipe Usaha': tipeUsaha,
          'Nomor Telepon': nomorTelepon.text,
        });
      });

      await addNotification(
        title: 'Pendaftaran Berhasil',
        message: 'Data pribadi dan usaha Anda telah tersimpan.',
      );

      Get.offAllNamed(Routes.home);
    }
  } catch (e) {
    print('Error saving data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menyimpan data')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTitle(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF3E63F4),
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          steps: getSteps(),
          currentStep: currentStep,
          onStepContinue: () {
            if (!formKeys[currentStep].currentState!.validate()) return;

            final isLastStep = currentStep == getSteps().length - 1;

            if (isLastStep) {
              saveData();
            } else {
              setState(() => currentStep += 1);
            }
          },
          onStepTapped: (step) => setState(() {
            currentStep = step;
          }),
          onStepCancel: currentStep == 0
              ? null
              : () => setState(() {
                    currentStep -= 1;
                  }),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final isLastStep = currentStep == getSteps().length - 1;

            return Container(
              margin: EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF080C67),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        isLastStep ? 'Simpan' : 'Selanjutnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: details.onStepContinue,
                    ),
                  ),
                  SizedBox(width: 12),
                  if (currentStep != 0)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A4A4A),
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
              ),
            );
          },
        ),
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: Text(
            'Info Pribadi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama Lengkap',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                TextFormField(
                  controller: namaLengkap,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama Lengkap tidak boleh kosong';
                    }
                    return null;
                  },
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                TextFormField(
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                TextFormField(
                  controller: tanggalLahir,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => _selectDate(context),
                      icon: Icon(Icons.calendar_month_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(),
                    ),
                    hintText: 'Pilih Tanggal Lahir',
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Jenis Kelamin',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: jenisKelamin,
                  isExpanded: true,
                  hint: Text('Pilih Jenis Kelamin'),
                  items: <String>['Laki-laki', 'Perempuan']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      jenisKelamin = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: Text(
            'Info Usaha',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKeys[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama Perusahaan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                TextFormField(
                  controller: namaUsaha,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama Perusahaan tidak boleh kosong';
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: tipeUsaha,
                  items: <String>['Perusahaan Dagang', 'Perusahaan Manufaktur']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      tipeUsaha = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Nomor Telepon',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                      return 'Format nomor telepon tidak valid';
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
        ),
      ];
}

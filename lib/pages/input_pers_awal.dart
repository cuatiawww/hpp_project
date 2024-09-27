import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hpp_project/service/database.dart';
import 'package:random_string/random_string.dart';

class InputPersAwal extends StatefulWidget {
  const InputPersAwal({super.key});

  @override
  State<InputPersAwal> createState() => _InputPersAwalState();
}
class _InputPersAwalState extends State<InputPersAwal> {
  TextEditingController namabarangcontroller = TextEditingController();
  TextEditingController hargacontroller = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController satuanController = TextEditingController(); // Input manual untuk satuan
  TextEditingController jumlahController = TextEditingController(); // Input untuk jumlah

  // Tambahkan variabel untuk DropdownButton
  String selectedUnit = 'Pcs'; // Default value
  List<String> units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya']; // Daftar satuan

  bool isOtherSelected = false; // Variabel untuk mengecek apakah "Lainnya" dipilih

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Input",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "PersAwal",
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 20.0, top: 30.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nama Barang",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: namabarangcontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Text(
                "Satuan",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedUnit, // Nilai terpilih
                  isExpanded: true, // Membuat dropdown penuh
                  icon: Icon(Icons.arrow_drop_down),
                  underline: SizedBox(), // Menghilangkan garis bawah
                  items: units.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUnit = newValue!;
                      isOtherSelected = newValue == 'Lainnya';
                    });
                  },
                ),
              ),
              SizedBox(height: 10.0),
              // Tampilkan TextField jika "Lainnya" dipilih
              isOtherSelected
                  ? Container(
                      padding: EdgeInsets.only(left: 10.0),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: satuanController, // Input manual untuk satuan
                        decoration: InputDecoration(
                          hintText: 'Masukkan satuan',
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : SizedBox(), // Jika bukan "Lainnya", kosongkan
              
              SizedBox(height: 10.0),

              // Inputan untuk jumlah
              Text(
                "Jumlah Satuan",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: jumlahController, // Input manual untuk jumlah
                  keyboardType: TextInputType.number, // Mengatur inputan ke angka
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah',
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              SizedBox(
                height: 20.0,
              ),
              Text(
                "Unit",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: unitController,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Text(
                "Harga",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: hargacontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
  // Validasi input apakah semua field sudah diisi
  if (namabarangcontroller.text.isEmpty ||
      jumlahController.text.isEmpty || // Tambahkan validasi untuk jumlah
      unitController.text.isEmpty ||
      hargacontroller.text.isEmpty ||
      (isOtherSelected && satuanController.text.isEmpty)) { // Validasi satuan hanya jika "Lainnya" dipilih
    Fluttertoast.showToast(
      msg: "Harap isi semua kolom!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    return;
  }

  // Mengonversi input menjadi tipe data yang sesuai
  String namaBarang = namabarangcontroller.text;
  String satuan = isOtherSelected ? satuanController.text : selectedUnit; // Gunakan unit dari dropdown jika bukan "Lainnya"
  int jumlah = int.parse(jumlahController.text); // Parse jumlah satuan
  int unit = int.parse(unitController.text);
  int harga = int.parse(hargacontroller.text);

  String Id = randomAlphaNumeric(10);

  Map<String, dynamic> barangInfoMap = {
    "Name": namaBarang,
    "Satuan": satuan,
    "Jumlah": jumlah, // Tambahkan jumlah dalam map
    "Unit": unit,
    "Price": harga,
    "Id": Id,
  };

  await DatabaseMethods().addBarang(barangInfoMap, Id).then((value) {
    Fluttertoast.showToast(
      msg: "Barang Details has been uploaded successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0);
  });
},

                  child: Text(
                    "Add",
                    style: TextStyle(
                        fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

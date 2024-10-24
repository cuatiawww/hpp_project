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
  TextEditingController namabarangcontroller = TextEditingController();
  TextEditingController hargacontroller = TextEditingController();
  TextEditingController satuanController = TextEditingController();
  TextEditingController jumlahController = TextEditingController();
  TextEditingController tipeController = TextEditingController();
  TextEditingController tanggalController = TextEditingController();

  String selectedUnit = 'Pcs';
  List<String> units = ['Pcs', 'Kg', 'Lt', 'Meter', 'Box', 'Lainnya'];
  bool isOtherSelected = false;
  DateTime selectedDate = DateTime.now();
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        tanggalController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Input",
              style: TextStyle(color: Colors.blue, fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Text(
              "PersAwal",
              style: TextStyle(color: Colors.orange, fontSize: 24.0, fontWeight: FontWeight.bold),
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
              Text("Nama Barang", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: namabarangcontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20.0),
              Text("Tipe", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: tipeController,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20.0),
              Text("Satuan", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedUnit,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  underline: SizedBox(),
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
              isOtherSelected
                  ? Container(
                      padding: EdgeInsets.only(left: 10.0),
                      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: satuanController,
                        decoration: InputDecoration(hintText: 'Masukkan satuan', border: InputBorder.none),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 10.0),
              Text("Jumlah Satuan", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'Masukkan jumlah', border: InputBorder.none),
                ),
              ),
              SizedBox(height: 10.0),
              Text("Harga", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: hargacontroller,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20.0),
              Text("Tanggal", style: TextStyle(color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: tanggalController,
                    decoration: InputDecoration(
                      hintText: 'Pilih tanggal',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (namabarangcontroller.text.isEmpty ||
                        jumlahController.text.isEmpty ||
                        hargacontroller.text.isEmpty ||
                        (isOtherSelected && satuanController.text.isEmpty) ||
                        tipeController.text.isEmpty ||
                        tanggalController.text.isEmpty) {
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

                    String namaBarang = namabarangcontroller.text;
                    String satuan = isOtherSelected ? satuanController.text : selectedUnit;
                    int jumlah = int.parse(jumlahController.text);
                    int harga = int.parse(hargacontroller.text);
                    String tipe = tipeController.text;
                    String tanggal = tanggalController.text;
                    String Id = randomAlphaNumeric(10);

                    Map<String, dynamic> barangInfoMap = {
                      "Name": namaBarang,
                      "Tipe": tipe,
                      "Satuan": satuan,
                      "Jumlah": jumlah,
                      "Price": harga,
                      "Id": Id,
                      "Tanggal": tanggal,
                    };

                    await DatabaseMethods().addBarang(barangInfoMap, Id).then((value) {
                      Fluttertoast.showToast(
                        msg: "Barang Details has been uploaded successfully",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      // Clear the fields after adding
                      namabarangcontroller.clear();
                      hargacontroller.clear();
                      satuanController.clear();
                      jumlahController.clear();
                      tipeController.clear();
                      tanggalController.clear();
                    });
                  },
                  child: Text(
                    "Add",
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
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

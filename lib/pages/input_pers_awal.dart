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
  TextEditingController namabarangcontroller = new TextEditingController();
  TextEditingController unitcontroller = new TextEditingController();
  TextEditingController hargacontroller = new TextEditingController();
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
      body: Container(
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
                controller: unitcontroller,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            SizedBox(
              height: 20.0,
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
            // Center(
            //   child: 
            Center(child:  ElevatedButton(
              onPressed: () async{
                String Id = randomAlphaNumeric(10);
                Map<String, dynamic> barangInfoMap = {
                      "Name": namabarangcontroller.text,
                      "Age": unitcontroller.text,
                      "Id": Id,
                      "Location": hargacontroller.text,
                    };
                     await DatabaseMethods()
                        .addBarang(barangInfoMap, Id)
                        .then((value) {
                      Fluttertoast.showToast(
                          msg:
                              "Barang Details has been uploaded successfully",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    });
                  }, 
            child: Text("Add", style: 
            TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            ),
            ),
           //       onPressed: () async {
            //         String Id = randomAlphaNumeric(10);
            //         
            //         await DatabaseMethods()
            //             .addEmployeeDetails(employeeInfoMap, Id)
            //             .then((value) {
            //           Fluttertoast.showToast(
            //               msg:
            //                   "Employee Details has been uploaded successfully",
            //               toastLength: Toast.LENGTH_SHORT,
            //               gravity: ToastGravity.CENTER,
            //               timeInSecForIosWeb: 1,
            //               backgroundColor: Colors.red,
            //               textColor: Colors.white,
            //               fontSize: 16.0);
            //         });
            //       },
            //       child: Text(
            //         "Add",
            //         style:
            //             TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            //       )),
            // )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hpp_project/pages/input_pers_awal.dart';
// import 'package:hpp_project/theme.dart';
// import 'package:flutter_svg/svg.dart';

class PersAwal extends StatefulWidget {
  const PersAwal({super.key});

  @override
  State<PersAwal> createState() => _PersAwalState();
}

class _PersAwalState extends State<PersAwal> {
    TextEditingController namecontroller = new TextEditingController();
  TextEditingController agecontroller = new TextEditingController();
  TextEditingController locationcontroller = new TextEditingController();
  Stream? EmployeeStream;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => InputPersAwal()));
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Perusahaan",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "Dagang",
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
        child: Column(
          children: [
            // Expanded(child: allEmployeeDetails()),
          ],
        ),
      ),
    );
  }

}

  // getontheload()async{
  //   EmployeeStream= await DatabaseMethods().getEmployeeDetails();
  //   setState(() {
      
  //   });
  // }
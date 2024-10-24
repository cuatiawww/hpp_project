import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pembelian.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/profile_page.dart';
import 'package:hpp_project/service/database.dart';
import 'package:hpp_project/theme.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_awal.dart'; // Add this import for the Pers Awal page
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:hpp_project/auth/controllers/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Default index untuk Beranda
  final authC = Get.find<AuthController>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Set indeks yang dipilih
    });
  }

  // Daftar halaman yang akan ditampilkan berdasarkan indeks
  static List<Widget> _widgetOptions = <Widget>[
    _PersAwalContent(), // Halaman Beranda
    ProfilePage(),
    ProfilePage()   // Halaman Laporan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: RichText(
          text: TextSpan(
            text: "Hai, ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            children: [
              TextSpan(
                text: "Username",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.only(right: 20),
              width: 30,
              height: 30,
              child: Image.asset(
                "assets/images/notification.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
        backgroundColor: primary1,
        elevation: 0,
      ),
      
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 24, // Sesuaikan ukuran ikon SVG
              width: 24,
              child: SvgPicture.asset(
                'assets/icons/home-2.svg',
                color: secondary,
              ),
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 24, // Sesuaikan ukuran ikon SVG
              width: 24,
              child: SvgPicture.asset(
                'assets/icons/note.svg',
                color: secondary,
              ),
            ),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 24, // Sesuaikan ukuran ikon SVG
              width: 24,
              child: SvgPicture.asset(
                'assets/icons/Profile.svg',
                color: secondary,
              ),
            ),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: secondary,
        selectedFontSize: 14,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Konten Beranda
class _PersAwalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: ClipPathClass(),
          child: Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            color: primary1,
          ),
        ),
        SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                ClipPath(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/shop.png",
                              height: 24, // Atur tinggi ikon sesuai kebutuhan
                              width: 24, // Atur lebar ikon sesuai kebutuhan
                            ),
                            SizedBox(width: 8), // Jarak antara ikon dan teks
                            Expanded(
                              child: Text(
                                "Toko Kelontong Azkhal Surya",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, // Untuk teks panjang
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            text: "Jenis Usaha: ",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            children: [
                              TextSpan(
                                text: "Perusahaan Dagang",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Divider(color: Colors.black),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/location.png",
                              height: 24,
                              width: 24,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: "Alamat Toko: ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Jl. Rusak Surya Zavier No. 69",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildMenu(context), // Pass context to _buildMenu
                SizedBox(height: 24),
                _buildLaporan(),
                SizedBox(height: 24),
                _buildRiwayat(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 20) / 3;
          return Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              // _buildMenuItem(Icons.add_circle, "Persediaan Awal", itemWidth, onPressed: () {
              //   Get.toNamed('/persediaan_awal');
              // }),
              _buildMenuItem(Icons.add_circle, "Persediaan Awal", itemWidth, 
              onPressed: () {
                Get.to(() => PersAwal());
              }),
              _buildMenuItem(Icons.add_circle, "Report Pembelian", itemWidth,
              onPressed: () {
                Get.to(() => PembelianPage());
              }),
              _buildMenuItem(Icons.report, "Persediaan Akhir", itemWidth,
              onPressed: () {
                Get.to(() => PersAkhirPage()); 
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, double itemWidth,
      {Function()? onPressed}) {
    return Container(
      width: itemWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(15),
              fixedSize: Size(60, 60),
              backgroundColor: Color(0xFF080C67),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLaporan() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Menjaga jarak antara teks dan tombol
    children: [
      Text(
        'Laporan',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
ElevatedButton(
  onPressed: () async {
    final pdf = pw.Document();
    
    // Fetch data from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection("Pembelian")
        .orderBy("Timestamp", descending: true)
        .get();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              var pembelian = snapshot.docs[index];
              String barangName = pembelian["BarangName"] ?? "Unknown";
              int jumlah = pembelian["Jumlah"] ?? 0;
              int price = pembelian["Price"] ?? 0;
              int totalCost = jumlah * price;

              return pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(barangName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("$jumlah pcs - Rp $price/pcs"),
                    pw.Text("Total: Rp $totalCost", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.document_scanner, size: 16),
      SizedBox(width: 8),
      Text('Print PDF'),
    ],
  ),
),
    ],
  ),
  SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green),
                    SizedBox(height: 8),
                    Text('Pemasukan'),
                    SizedBox(height: 4),
                    Text('Rp 500.000',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.red),
                    SizedBox(height: 8),
                    Text('Pengeluaran'),
                    SizedBox(height: 4),
                    Text('Rp 10.000.000',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 Widget _buildRiwayat() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 25),
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Riwayat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseMethods().getPembelianDetails(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }

            List<RiwayatItem> riwayatItems = [];
            snapshot.data!.docs.forEach((doc) {
              riwayatItems.add(
                RiwayatItem(
                  title: doc["BarangId"],
                  description: "${doc["Jumlah"]} unit - Rp ${doc["Price"]}",
                  price: "Rp ${doc["Jumlah"] * doc["Price"]}",
                ),
              );
            });

            return Container(
              height: 300, // Set a fixed height for the list
              child: ListView.builder(
                itemCount: riwayatItems.length,
                shrinkWrap: true, // Allow the list to shrink to fit its content
                itemBuilder: (context, index) {
                  return riwayatItems[index];
                },
              ),
            );
          },
        ),
        SizedBox(height: 16),
        Text(
          'Total Biaya: Rp ${_calculateTotalBiaya()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

int _calculateTotalBiaya() {
  int totalBiaya = 0;
  DatabaseMethods().getPembelianDetails().listen((event) {
    event.docs.forEach((doc) {
      totalBiaya += (doc["Jumlah"] * doc["Price"]) as int;
    });
  });
  return totalBiaya;
}
}

class RiwayatItem extends StatelessWidget {
  final String title;
  final String description;
  final String price;

  const RiwayatItem({
    required this.title,
    required this.description,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(description),
          SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom ClipPath
class ClipPathClass extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 100);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 100);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

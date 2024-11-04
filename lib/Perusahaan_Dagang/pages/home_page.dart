import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/pembelian.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/profile_page.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:hpp_project/theme.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/pers_awal.dart';
import 'package:intl/intl.dart';
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
  int _selectedIndex = 0;
  final authC = Get.find<AuthController>();
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Re-initialize controllers with new user
        Get.delete<DataPribadiController>();
        Get.delete<DataUsahaController>();
        final dataPribadiC = Get.put(DataPribadiController(uid: user.uid), tag: user.uid);
        final dataUsahaC = Get.put(DataUsahaController(uid: user.uid), tag: user.uid);
        // Load data for new user
        dataPribadiC.fetchDataPribadi(user.uid);
        dataUsahaC.fetchDataUsaha(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static List<Widget> _widgetOptions = <Widget>[
    _PersAwalContent(),
    ProfilePage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: currentUser != null ? GetX<DataPribadiController>(
          tag: currentUser.uid,
          builder: (controller) => RichText(
            text: TextSpan(
              text: "Hai, ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text: controller.namaLengkap.value.isEmpty 
                      ? 'Memuat...' 
                      : controller.namaLengkap.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ) : Text("Hai, Tamu"),
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
              height: 24,
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
              height: 24,
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
              height: 24,
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

class _PersAwalContent extends StatefulWidget {
  @override
  State<_PersAwalContent> createState() => _PersAwalContentState();
}

class _PersAwalContentState extends State<_PersAwalContent> {
  late DataPribadiController dataPribadiC;
  late DataUsahaController dataUsahaC;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  void initializeControllers() {
    // Pastikan ada user yang login
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      dataPribadiC = Get.put(DataPribadiController(uid: currentUser.uid), tag: currentUser.uid);
      dataUsahaC = Get.put(DataUsahaController(uid: currentUser.uid), tag: currentUser.uid);
      loadUserData();
    }
  }

  Future<void> loadUserData() async {
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      try {
        await dataPribadiC.fetchDataPribadi(currentUser.uid);
        await dataUsahaC.fetchDataUsaha(currentUser.uid);
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }
  
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
                _buildProfileCard(),
                SizedBox(height: 24),
                _buildMenu(context),
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

  Widget _buildProfileCard() {
    final currentUser = auth.currentUser;
    
    if (currentUser == null) {
      return Center(child: Text('Silakan login terlebih dahulu'));
    }

    return ClipPath(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/images/shop.png",
                  height: 24,
                  width: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                    dataUsahaC.namaUsaha.value.isEmpty 
                        ? 'Memuat...' 
                        : dataUsahaC.namaUsaha.value,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ),
              ],
            ),
            SizedBox(height: 20),
            Obx(() => RichText(
              text: TextSpan(
                text: "Tipe Usaha: ",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(
                    text: dataUsahaC.tipeUsaha.value.isEmpty 
                        ? 'Memuat...' 
                        : dataUsahaC.tipeUsaha.value,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            )),
            SizedBox(height: 10),
            Divider(color: Colors.black),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Obx(() => RichText(
                    text: TextSpan(
                      text: "Nomor Telepon: ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: dataUsahaC.nomorTelepon.value.isEmpty 
                              ? 'Memuat...' 
                              : dataUsahaC.nomorTelepon.value,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
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
      margin: EdgeInsets.symmetric(horizontal: 20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  pw.Text(barangName,
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold)),
                                  pw.Text("$jumlah pcs - Rp $price/pcs"),
                                  pw.Text("Total: Rp $totalCost",
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
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
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 30),
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
            stream: FirebaseFirestore.instance
                .collection("Pembelian")
                .orderBy('Tanggal', descending: true)
                .snapshots(),
            builder: (context, pembelianSnapshot) {
              if (pembelianSnapshot.hasError) {
                return Text('Error: ${pembelianSnapshot.error}');
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Barang")
                    .orderBy('Tanggal', descending: true)
                    .snapshots(),
                builder: (context, barangSnapshot) {
                  if (pembelianSnapshot.connectionState == ConnectionState.waiting ||
                      barangSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (barangSnapshot.hasError) {
                    return Text('Error: ${barangSnapshot.error}');
                  }

                  List<RiwayatItem> riwayatItems = [];
                  
                  // Add Persediaan Awal items
                  if (barangSnapshot.hasData) {
                    for (var doc in barangSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      riwayatItems.add(
                        RiwayatItem(
                          title: data["Name"] ?? "Unknown",
                          description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])} (Persediaan Awal)",
                          price: "Rp ${NumberFormat('#,###').format((data["Jumlah"] as int) * (data["Price"] as int))}",
                        ),
                      );
                    }
                  }

                  // Add Pembelian items
                  if (pembelianSnapshot.hasData) {
                    for (var doc in pembelianSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      riwayatItems.add(
                        RiwayatItem(
                          title: data["Name"] ?? "Unknown",
                          description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])} (Pembelian)",
                          price: "Rp ${NumberFormat('#,###').format((data["Jumlah"] as int) * (data["Price"] as int))}",
                        ),
                      );
                    }
                  }

                  if (riwayatItems.isEmpty) {
                    return Center(child: Text('Tidak ada riwayat'));
                  }

                  return Column(
                    children: [
                      Container(
                        height: 300,
                        child: ListView.builder(
                          itemCount: riwayatItems.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return riwayatItems[index];
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Total Biaya: Rp ${NumberFormat('#,###').format(_calculateTotalBiaya(pembelianSnapshot.data?.docs ?? [], barangSnapshot.data?.docs ?? []))}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  int _calculateTotalBiaya(List<QueryDocumentSnapshot> pembelianDocs, List<QueryDocumentSnapshot> barangDocs) {
    int total = 0;
    
    // Calculate total from Pembelian
    for (var doc in pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["Jumlah"] as int) * (data["Price"] as int);
    }
    
    // Calculate total from Persediaan Awal
    for (var doc in barangDocs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["Jumlah"] as int) * (data["Price"] as int);
    }
    
    return total;
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
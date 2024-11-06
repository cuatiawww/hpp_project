// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/penjualan_page.dart';
import 'package:hpp_project/laporan_page.dart';
import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_calculation_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pembelian_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/profile_page.dart';
import 'package:hpp_project/auth/controllers/data_pribadi_controller.dart';
import 'package:hpp_project/auth/controllers/data_usaha_controller.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_awal_page.dart';
import 'package:hpp_project/report_persediaan_page.dart';
import 'package:intl/intl.dart';
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

  static final List<Widget> _widgetOptions = <Widget>[
  _PersAwalContent(),
  LaporanPage(),
  ProfilePage()
];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color:Color(0xFF080C67),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  currentUser != null ? GetX<DataPribadiController>(
                    tag: currentUser.uid,
                    builder: (controller) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hello,",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          controller.namaLengkap.value.isEmpty 
                              ? 'Loading...' 
                              : controller.namaLengkap.value + "!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ) : Text("Welcome, Guest"),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Color(0xFF080C67),
        elevation: 0,
      ),
      body: _widgetOptions[_selectedIndex],
    bottomNavigationBar: Container(
  margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
  height: 64,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 0),
      ),
    ],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildNavItem(
        index: 0,
        icon: 'assets/icons/home-2.svg',
        label: 'Beranda',
        isSelected: _selectedIndex == 0,
      ),
      _buildNavItem(
        index: 1,
        icon: 'assets/icons/note.svg',
        label: 'Laporan',
        isSelected: _selectedIndex == 1,
      ),
      _buildNavItem(
        index: 2,
        icon: 'assets/icons/Profile.svg',
        label: 'Akun',
        isSelected: _selectedIndex == 2,
      ),
    ],
  ),
),
    );
  }
  
  
  Widget _buildNavItem({
  required int index,
  required String icon,
  required String label,
  required bool isSelected,
}) {
  return GestureDetector(
    onTap: () => _onItemTapped(index),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF080C67).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: SvgPicture.asset(
              icon,
              color: isSelected ? Color(0xFF080C67) : Colors.grey,
            ),
          ),
          if (isSelected) ...[
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF080C67),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
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
//SCROLLABLE  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: ClipPathClass(),
          child: Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            color:Color(0xFF080C67),
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

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 15),
    child: Stack(
      children: [
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF080C67),  // Primary blue
                Color(0xFF1E23A7),  // Lighter blue
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      "assets/images/shop.png",
                      height: 24,
                      width: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Text(
                      dataUsahaC.namaUsaha.value.isEmpty 
                          ? 'Memuat...' 
                          : dataUsahaC.namaUsaha.value,
                      style: TextStyle(
                        color: Colors.white,
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: dataUsahaC.tipeUsaha.value.isEmpty 
                          ? 'Memuat...' 
                          : dataUsahaC.tipeUsaha.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              )),
              SizedBox(height: 10),
              Divider(color: Colors.white.withOpacity(0.2)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => RichText(
                      text: TextSpan(
                        text: "Nomor Telepon: ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: dataUsahaC.nomorTelepon.value.isEmpty 
                                ? 'Memuat...' 
                                : dataUsahaC.nomorTelepon.value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
      ],
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
      child: Column(
        children: [
          // Menu Items
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 25) / 4;
              return Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  _buildMenuItem(Icons.add_circle, "Persediaan\nAwal", itemWidth,
                      onPressed: () {
                    Get.to(() => PersAwal());
                  }),
                  _buildMenuItem(Icons.shopping_cart, "Pembelian", itemWidth,
                      onPressed: () {
                    Get.to(() => PembelianPage());
                  }),
                  _buildMenuItem(Icons.point_of_sale, "Penjualan", itemWidth,
                      onPressed: () {
                    Get.to(() => PenjualanPage());
                  }),
                  _buildMenuItem(Icons.inventory_2, "Persediaan\nAkhir", itemWidth,
                      onPressed: () {
                    Get.to(() => PersAkhirPage());
                  }),
                ],
              );
            },
          ),
          // Spacing between menu items and HPP button
          SizedBox(height: 20),
          // HPP Button
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => HPPCalculationPage());
              },
              icon: Icon(Icons.calculate, color: Colors.white),
              label: Text(
                'Hitung HPP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF080C67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
}
// Sesuaikan style menu item agar tetap rapi dengan 4 kolom
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
            fixedSize: Size(50, 50), // Sesuaikan ukuran button
            backgroundColor: Color(0xFF080C67),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 25, // Sesuaikan ukuran icon
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12, // Sesuaikan ukuran text
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

//LAPORAN UI
Widget _buildLaporan() {
  final userId = auth.currentUser?.uid;
  if (userId == null) return Container();

  // Get current month date range
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);
  final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
  final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

  // Format bulan dalam Bahasa Indonesia
  final List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 
    'Mei', 'Juni', 'Juli', 'Agustus',
    'September', 'Oktober', 'November', 'Desember'
  ];
  final String monthYear = '${monthNames[now.month - 1]} ${now.year}';

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.all(20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Laporan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF080C67).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                monthYear,
                style: TextStyle(
                  color: Color(0xFF080C67),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .collection("Penjualan")
              .where('tanggal', isGreaterThanOrEqualTo: startDateStr)
              .where('tanggal', isLessThanOrEqualTo: endDateStr)
              .snapshots(),
          builder: (context, penjualanSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(userId)
                  .collection("Pembelian")
                  .where('Tanggal', isGreaterThanOrEqualTo: startDateStr)
                  .where('Tanggal', isLessThanOrEqualTo: endDateStr)
                  .snapshots(),
              builder: (context, pembelianSnapshot) {
                double totalPenjualan = 0;
                double totalPembelian = 0;

                if (penjualanSnapshot.hasData) {
                  for (var doc in penjualanSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalPenjualan += (data['total'] ?? 0).toDouble();
                  }
                }

                if (pembelianSnapshot.hasData) {
                  for (var doc in pembelianSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalPembelian += ((data['Jumlah'] ?? 0) * (data['Price'] ?? 0)).toDouble();
                  }
                }

                return Column(
                  children: [
                    _buildTransactionCard(
                      "Penjualan",
                      totalPenjualan,
                      Icons.arrow_circle_down,
                      Colors.green.shade100,
                      Colors.green,
                      true,
                    ),
                    SizedBox(height: 12),
                    _buildTransactionCard(
                      "Pembelian",
                      totalPembelian,
                      Icons.arrow_circle_up,
                      Colors.red.shade100,
                      Colors.red,
                      false,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => ReportPersediaanPage()),
                        icon: Icon(Icons.document_scanner, size: 18,),
                        label: Text(
                          'Report Persediaan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 255, 255, 255)
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF080C67),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

Widget _buildTransactionCard(
  String title,
  double amount,
  IconData icon,
  Color backgroundColor,
  Color iconColor,
  bool isIncome,
) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Made semi-bold
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
//----------------------------------------------------------------
Widget _buildMonthLabel() {
  final now = DateTime.now();
  // Format bulan dan tahun dalam Bahasa Indonesia
  final List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 
    'Mei', 'Juni', 'Juli', 'Agustus',
    'September', 'Oktober', 'November', 'Desember'
  ];
  final String monthYear = '${monthNames[now.month - 1]} ${now.year}';

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Color(0xFF080C67).withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      monthYear,
      style: TextStyle(
        color: Color(0xFF080C67),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}
Widget _buildRiwayat() {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20, bottom: 30),
    padding: EdgeInsets.all(20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildMonthLabel(), // Menggunakan widget baru untuk menampilkan bulan
          ],
        ),
        SizedBox(height: 16),
        _buildRiwayatContent(),
      ],
    ),
  );
}

Widget _buildRiwayatContent() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("Users")
        .doc(auth.currentUser?.uid)
        .collection("Pembelian")
        .orderBy('Tanggal', descending: true)
        .snapshots(),
    builder: (context, pembelianSnapshot) {
      if (pembelianSnapshot.hasError) {
        return _buildErrorState('Terjadi kesalahan saat memuat data');
      }

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(auth.currentUser?.uid)
            .collection("Barang")
            .orderBy('Tanggal', descending: true)
            .snapshots(),
        builder: (context, barangSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Users")
                .doc(auth.currentUser?.uid)
                .collection("Penjualan")
                .orderBy('tanggal', descending: true)
                .snapshots(),
            builder: (context, penjualanSnapshot) {
              if (pembelianSnapshot.connectionState == ConnectionState.waiting ||
                  barangSnapshot.connectionState == ConnectionState.waiting ||
                  penjualanSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (barangSnapshot.hasError || penjualanSnapshot.hasError) {
                return _buildErrorState('Terjadi kesalahan saat memuat data');
              }

              List<RiwayatItem> riwayatItems = [];
              
              // Add Persediaan Awal items
              if (barangSnapshot.hasData) {
                for (var doc in barangSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  riwayatItems.add(
                    RiwayatItem(
                      title: data["Name"] ?? "Unknown",
                      description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])}",
                      price: (data["Jumlah"] as int) * (data["Price"] as int),
                      type: "Persediaan Awal",
                      date: data["Tanggal"] ?? "",
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
                      description: "${data["Jumlah"]} ${data["Satuan"]} - Rp ${NumberFormat('#,###').format(data["Price"])}",
                      price: (data["Jumlah"] as int) * (data["Price"] as int),
                      type: "Pembelian",
                      date: data["Tanggal"] ?? "",
                    ),
                  );
                }
              }

              // Add Penjualan items
              if (penjualanSnapshot.hasData) {
                for (var doc in penjualanSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  riwayatItems.add(
                    RiwayatItem(
                      title: data["namaBarang"] ?? "Unknown",
                      description: "${data["jumlah"]} ${data["satuan"]} - Rp ${NumberFormat('#,###').format(data["hargaJual"])}",
                      price: data["total"] ?? 0,
                      type: "Penjualan",
                      date: data["tanggal"] ?? "",
                    ),
                  );
                }
              }

              // Sort all items by date
              riwayatItems.sort((a, b) {
                return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
              });

              if (riwayatItems.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  Container(
                    height: 300,
                    child: ListView.builder(
                      itemCount: riwayatItems.length,
                      padding: EdgeInsets.only(top: 8),
                      itemBuilder: (context, index) {
                        return riwayatItems[index];
                      },
                    ),
                  ),
                  Divider(height: 32, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Biaya:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(_calculateTotalBiaya(pembelianSnapshot.data?.docs ?? [], barangSnapshot.data?.docs ?? []))}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF080C67),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

// State widgets remain the same
Widget _buildLoadingState() {
  return Container(
    height: 200,
    child: Center(
      child: CircularProgressIndicator(
        color: Color(0xFF080C67),
      ),
    ),
  );
}

Widget _buildErrorState(String message) {
  return Container(
    height: 200,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildEmptyState() {
  return Container(
    height: 200,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: Colors.grey[400],
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada riwayat transaksi',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

// RiwayatItem Widget
class RiwayatItem extends StatelessWidget {
  final String title;
  final String description;
  final int price;
  final String type;
  final String date;

  const RiwayatItem({
    Key? key,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color and icon based on type
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case "Penjualan":
        typeColor = Colors.green;
        typeIcon = Icons.shopping_bag_outlined;
        break;
      case "Pembelian":
        typeColor = Colors.red;
        typeIcon = Icons.shopping_cart_outlined;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.inventory_outlined;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Rp ${NumberFormat('#,###').format(price)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
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
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpp_project/profit_widget.dart';
import 'package:intl/intl.dart';
import 'package:hpp_project/service/database.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({Key? key}) : super(key: key);

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseMethods _db = DatabaseMethods();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  final ValueNotifier<double> _totalPenjualan = ValueNotifier(0);
  final ValueNotifier<double> _totalPembelian = ValueNotifier(0);
  final ValueNotifier<int> _totalBarangTerjual = ValueNotifier(0);
  
  Stream<QuerySnapshot<Map<String, dynamic>>>? _penjualanStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _pembelianStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

 void _initializeData() {
  if (!mounted) return;
  
  final startDate = '$_selectedMonth-01';
  final date = DateTime.parse(startDate);
  final endDate = DateTime(date.year, date.month + 1, 0);
  final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

  setState(() {
    _penjualanStream = _db.getLaporanPenjualanStream(startDate, endDateStr);
    _pembelianStream = _db.getLaporanPembelianStream(startDate, endDateStr);
  });
  
  _loadInitialData();
}

 void _loadInitialData() async {
  try {
    final startDate = '$_selectedMonth-01';
    final date = DateTime.parse(startDate);
    final endDate = DateTime(date.year, date.month + 1, 0);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Reset the values before loading new data
    _totalPenjualan.value = 0;
    _totalPembelian.value = 0;
    _totalBarangTerjual.value = 0;

    final penjualanDocs = await _db.getLaporanPenjualanStream(startDate, endDateStr).first;
    if (penjualanDocs.docs.isNotEmpty) {
      _calculatePenjualanStats(penjualanDocs.docs);
    }

    final pembelianDocs = await _db.getLaporanPembelianStream(startDate, endDateStr).first;
    if (pembelianDocs.docs.isNotEmpty) {
      _calculatePembelianStats(pembelianDocs.docs);
    }
  } catch (e) {
    print('Error loading initial data: $e');
  }
}
 
  void _initializeStreams() {
    if (!mounted) return;
    
    final startDate = '$_selectedMonth-01';
    final date = DateTime.parse(startDate);
    final endDate = DateTime(date.year, date.month + 1, 0);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    setState(() {
      _penjualanStream = _db.getLaporanPenjualanStream(startDate, endDateStr);
      _pembelianStream = _db.getLaporanPembelianStream(startDate, endDateStr);
    });

    _loadInitialData();
  }

 void _calculatePenjualanStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  if (!mounted) return;
    
  double tempTotalPenjualan = 0;
  int tempTotalBarangTerjual = 0;

  for (var doc in docs) {
    final data = doc.data();
    // Make sure we're checking for the correct date format and field
    if (data['tanggal'] != null && data['tanggal'].toString().startsWith(_selectedMonth)) {
      final hargaJual = (data['hargaJual'] as num?)?.toDouble() ?? 0;
      final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
      
      // Update both values
      tempTotalPenjualan += (hargaJual * jumlah);
      tempTotalBarangTerjual += jumlah;  // Make sure this line executes
      
      // Add debug print to verify calculations
      print('Processing sale: Price: $hargaJual, Quantity: $jumlah');
      print('Running totals - Sales: $tempTotalPenjualan, Items: $tempTotalBarangTerjual');
    }
  }

  // Update the ValueNotifiers
  if (mounted) {
    _totalPenjualan.value = tempTotalPenjualan;
    _totalBarangTerjual.value = tempTotalBarangTerjual;
    
    // Add debug print to verify final values
    print('Final values - Total Sales: ${_totalPenjualan.value}, Total Items: ${_totalBarangTerjual.value}');
  }
}

  void _calculatePembelianStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (!mounted) return;
    
    double tempTotalPembelian = 0;

    for (var doc in docs) {
      final data = doc.data();
      if (data['Tanggal'] != null && data['Tanggal'].startsWith(_selectedMonth)) {
        final harga = (data['Price'] as num?)?.toDouble() ?? 0;
        final jumlah = (data['Jumlah'] as num?)?.toInt() ?? 0;
        tempTotalPembelian += (harga * jumlah);
      }
    }

    _totalPembelian.value = tempTotalPembelian;
  }

  List<DropdownMenuItem<String>> _buildMonthDropdownItems() {
    return List.generate(12, (index) {
      final date = DateTime.now().subtract(Duration(days: 30 * index));
      final value = DateFormat('yyyy-MM').format(date);
      return DropdownMenuItem(
        value: value,
        child: Text(
          DateFormat('MMMM yyyy').format(date),
          style: const TextStyle(fontSize: 14),
        ),
      );
    });
  }

   void _onMonthChanged(String? newValue) {
  if (newValue != null && mounted) {
    setState(() {
      _selectedMonth = newValue;
      _initializeData();  // Ini akan memperbarui stream
      
      // Reset values
      _totalPenjualan.value = 0;
      _totalPembelian.value = 0;
      _totalBarangTerjual.value = 0;
    });
  }
}
  @override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  
  return Scaffold(
    backgroundColor: Color(0xFFF8FAFC),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(constraints),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.25, // 25% dari tinggi layar
                        child: _buildStatisticsCards(constraints),
                      ),
                      SizedBox(height: 16),
                      if (_penjualanStream != null && _pembelianStream != null)
                        Container(
                          height: screenHeight * 0.4, // 40% dari tinggi layar
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ProfitReportWidget(
                            penjualanStream: _penjualanStream!,
                            pembelianStream: _pembelianStream!,
                            selectedMonth: _selectedMonth,
                          ),
                        ),
                      SizedBox(height: 16),
                      Container(
                        height: screenHeight * 0.35, // 35% dari tinggi layar
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTabBar(),
                            Expanded(
                              child: _buildTabBarView(constraints),
                            ),
                          ],
                        ),
                      ),
                    ],
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


  Widget _buildHeader(BoxConstraints constraints) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleAndDatePicker(constraints.maxWidth > 600),
      ],
    ),
  );
}

  Widget _buildTitleAndDatePicker(bool isWideScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Laporan',
          style: TextStyle(
            fontSize: isWideScreen ? 28 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildMonthPicker(isWideScreen),
      ],
    );
  }

  Widget _buildMonthPicker(bool isWideScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 16 : 12,
        vertical: isWideScreen ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: isWideScreen ? 24 : 20),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedMonth,
            underline: Container(),
            items: _buildMonthDropdownItems(),
            onChanged: _onMonthChanged,
            style: TextStyle(
              fontSize: isWideScreen ? 16 : 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BoxConstraints constraints) {
    final isWideScreen = constraints.maxWidth > 600;
    final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
    final childAspectRatio = isWideScreen ? 1.8 : 1.5;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _penjualanStream,
      builder: (context, penjualanSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _pembelianStream,
          builder: (context, pembelianSnapshot) {
            // Update statistics when either stream updates
            if (penjualanSnapshot.hasData) {
              final docs = penjualanSnapshot.data!.docs.where((doc) {
                final data = doc.data();
                return data['tanggal'] != null && 
                       data['tanggal'].startsWith(_selectedMonth);
              }).toList();
              _calculatePenjualanStats(docs);
            }

            if (pembelianSnapshot.hasData) {
              final docs = pembelianSnapshot.data!.docs.where((doc) {
                final data = doc.data();
                return data['Tanggal'] != null && 
                       data['Tanggal'].startsWith(_selectedMonth);
              }).toList();
              _calculatePembelianStats(docs);
            }

            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isWideScreen ? 24 : 16,
              mainAxisSpacing: isWideScreen ? 24 : 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(
                  'Total\nPenjualan',
                  _totalPenjualan,
                  Icons.arrow_upward_rounded,
                  Color(0xFF4CAF50),
                  [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  isWideScreen: isWideScreen,
                ),
                _buildStatCard(
                  'Total\nPembelian',
                  _totalPembelian,
                  Icons.arrow_downward_rounded,
                  Color(0xFFE53935),
                  [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
                  isWideScreen: isWideScreen,
                ),
                _buildStatCard(
                  'Jumlah\nTerjual',
                  ValueNotifier(_totalBarangTerjual.value.toDouble()),
                  Icons.inventory_2_rounded,
                  Color(0xFF1976D2),
                  [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  isCount: true,
                  isWideScreen: isWideScreen,
                ),
                _buildProfitCard(isWideScreen),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfitCard(bool isWideScreen) {
    return ValueListenableBuilder<double>(
      valueListenable: _totalPenjualan,
      builder: (context, penjualan, _) {
        return ValueListenableBuilder<double>(
          valueListenable: _totalPembelian,
          builder: (context, pembelian, _) {
            final profit = penjualan - pembelian;
            return _buildStatCard(
              'Profit',
              ValueNotifier(profit),
              profit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              profit >= 0 ? Color(0xFF9C27B0) : Color(0xFFFF7043),
              profit >= 0 
                  ? [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]
                  : [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
              isWideScreen: isWideScreen,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    ValueNotifier<double> value,
    IconData icon,
    Color iconColor,
    List<Color> gradientColors, {
    bool isCount = false,
    required bool isWideScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(isWideScreen ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.5),
            blurRadius: isWideScreen ? 15 : 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isWideScreen ? 20 : 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(isWideScreen ? 20 : 16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCardHeader(title, icon, iconColor, isWideScreen),
                ValueListenableBuilder<double>(
                  valueListenable: value,
                  builder: (context, val, _) => 
                      _buildStatCardValue(val, isCount, isWideScreen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardHeader(String title, IconData icon, Color iconColor, bool isWideScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isWideScreen ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: EdgeInsets.all(isWideScreen ? 10 : 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isWideScreen ? 14 : 12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isWideScreen ? 24 : 20,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardValue(double value, bool isCount, bool isWideScreen) {
    return Text(
      isCount
          ? value.toInt().toString()
          : NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
      style: TextStyle(
        color: Colors.black,
        fontSize: isWideScreen ? 24 : 20,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

Widget _buildTabBar() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    child: TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF080C67),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF080C67),
      indicatorWeight: 3,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12, // Ukuran font lebih kecil
      ),
      tabs: const [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward_rounded, size: 16),
              SizedBox(width: 4),
              Text('Penjualan'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward_rounded, size: 16),
              SizedBox(width: 4),
              Text('Pembelian'),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTabBarView(BoxConstraints constraints) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTransactionTab(_penjualanStream, true, constraints),
        _buildTransactionTab(_pembelianStream, false, constraints),
      ],
    );
  }

   Widget _buildTransactionTab(
    Stream<QuerySnapshot<Map<String, dynamic>>>? stream,
    bool isPenjualan,
    BoxConstraints constraints,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada data untuk bulan ini',
              style: TextStyle(
                fontSize: constraints.maxWidth > 600 ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final dateField = isPenjualan ? 'tanggal' : 'Tanggal';
          return data[dateField] != null && 
                 data[dateField].startsWith(_selectedMonth);
        }).toList();

        // Update statistics when data changes
        if (isPenjualan) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculatePenjualanStats(docs);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculatePembelianStats(docs);
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada data untuk bulan ini',
              style: TextStyle(
                fontSize: constraints.maxWidth > 600 ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return _buildTransactionList(docs, isPenjualan, constraints);
      },
    );
  }

  Widget _buildTransactionList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    bool isPenjualan,
    BoxConstraints constraints,
  ) {
    final isWideScreen = constraints.maxWidth > 600;
    final padding = isWideScreen ? 24.0 : 16.0;

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: documents.length,
      itemBuilder: (context, index) => 
          _buildTransactionCard(documents[index], isPenjualan, isWideScreen),
    );
  }

  Widget _buildTransactionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    bool isPenjualan,
    bool isWideScreen,
  ) {
    final data = document.data();
    
    // Data processing
    final String title = isPenjualan ? data['namaBarang'] ?? '' : data['Name'] ?? '';
    final int quantity = isPenjualan ? data['jumlah'] ?? 0 : data['Jumlah'] ?? 0;
    final String unit = data['satuan'] ?? '';
    final double price = isPenjualan 
        ? (data['hargaJual']?.toDouble() ?? 0)
        : (data['Price']?.toDouble() ?? 0);
    final double total = isPenjualan 
        ? (data['total']?.toDouble() ?? 0)
        : ((data['Jumlah'] ?? 0) * (data['Price'] ?? 0)).toDouble();
    final String date = isPenjualan ? data['tanggal'] ?? '' : data['Tanggal'] ?? '';
    
    // Gradient colors based on transaction type
    List<Color> typeGradient = isPenjualan 
        ? [Color(0xFF00B07D), Color(0xFF00CA8E)]  // Green gradient for sales
        : [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]; // Red gradient for purchases
        
    IconData typeIcon = isPenjualan 
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 6,
      horizontal: 8,
      ),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  gradient: LinearGradient(
                    colors: typeGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  color: Colors.white,
                  size: isWideScreen ? 24 : 20,
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
                        fontSize: isWideScreen ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: isWideScreen ? 14 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 16 : 12,
                  vertical: isWideScreen ? 8 : 6
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: typeGradient.map((c) => c.withOpacity(0.15)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPenjualan ? 'Penjualan' : 'Pembelian',
                  style: TextStyle(
                    color: typeGradient[0],
                    fontSize: isWideScreen ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isWideScreen ? 16 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$quantity $unit - ${NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(price)}',
                  style: TextStyle(
                    fontSize: isWideScreen ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: typeGradient,
                ).createShader(bounds),
                child: Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(total),
                  style: TextStyle(
                    fontSize: isWideScreen ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalPenjualan.dispose();
    _totalPembelian.dispose();
    _totalBarangTerjual.dispose();
    super.dispose();
  }
}
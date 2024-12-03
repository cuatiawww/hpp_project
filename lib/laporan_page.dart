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
   final ValueNotifier<double> _penjualanPercentage = ValueNotifier(0);
  final ValueNotifier<double> _pembelianPercentage = ValueNotifier(0);
  final ValueNotifier<double> _profitPercentage = ValueNotifier(0);
  
  Stream<QuerySnapshot<Map<String, dynamic>>>? _penjualanStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _pembelianStream;

  @override
   void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Delay inisialisasi data untuk mengurangi beban awal
    Future.microtask(() => _initializeData());
  }

void _initializeData() {
  if (!mounted) return;
  
  final startDate = '$_selectedMonth-01';
  final date = DateTime.parse(startDate);
  final endDate = DateTime(date.year, date.month + 1, 0);
  final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

  setState(() {
    // Gunakan where clause di query Firestore langsung untuk filtering
    _penjualanStream = _db.getLaporanPenjualanStream(startDate, endDateStr)
      .map((snapshot) {
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['tanggal'] != null && 
                 data['tanggal'].toString().startsWith(_selectedMonth);
        }).toList();
        return snapshot;
      });
    
    _pembelianStream = _db.getLaporanPembelianStream(startDate, endDateStr)
      .map((snapshot) {
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['Tanggal'] != null && 
                 data['Tanggal'].toString().startsWith(_selectedMonth);
        }).toList();
        return snapshot;
      });
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

  Future<Map<String, double>> _getPreviousMonthData(String currentMonth) async {
    final currentDate = DateTime.parse('$currentMonth-01');
    final previousMonth = DateTime(currentDate.year, currentDate.month - 1);
    final previousMonthStr = DateFormat('yyyy-MM').format(previousMonth);
    
    final startDate = '$previousMonthStr-01';
    final endDate = DateTime(previousMonth.year, previousMonth.month + 1, 0);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    double previousPenjualan = 0;
    double previousPembelian = 0;

    try {
      final penjualanDocs = await _db.getLaporanPenjualanStream(startDate, endDateStr).first;
      final pembelianDocs = await _db.getLaporanPembelianStream(startDate, endDateStr).first;

      for (var doc in penjualanDocs.docs) {
        final data = doc.data();
        if (data['tanggal'] != null && data['tanggal'].toString().startsWith(previousMonthStr)) {
          final hargaJual = (data['hargaJual'] as num?)?.toDouble() ?? 0;
          final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
          previousPenjualan += (hargaJual * jumlah);
        }
      }

      for (var doc in pembelianDocs.docs) {
        final data = doc.data();
        if (data['Tanggal'] != null && data['Tanggal'].startsWith(previousMonthStr)) {
          final harga = (data['Price'] as num?)?.toDouble() ?? 0;
          final jumlah = (data['Jumlah'] as num?)?.toInt() ?? 0;
          previousPembelian += (harga * jumlah);
        }
      }
    } catch (e) {
      print('Error getting previous month data: $e');
    }

    return {
      'penjualan': previousPenjualan,
      'pembelian': previousPembelian,
    };
  }
 
 void _calculatePenjualanStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (!mounted) return;
    
    double tempTotalPenjualan = 0;
    int tempTotalBarangTerjual = 0;

    for (var doc in docs) {
      final data = doc.data();
      if (data['tanggal'] != null && data['tanggal'].toString().startsWith(_selectedMonth)) {
        final hargaJual = (data['hargaJual'] as num?)?.toDouble() ?? 0;
        final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
        tempTotalPenjualan += (hargaJual * jumlah);
        tempTotalBarangTerjual += jumlah;
      }
    }

    final previousData = await _getPreviousMonthData(_selectedMonth);
    final previousPenjualan = previousData['penjualan'] ?? 0;
    
    double percentageChange = 0;
    if (previousPenjualan > 0 && tempTotalPenjualan > 0) {
      percentageChange = ((tempTotalPenjualan - previousPenjualan) / previousPenjualan) * 100;
    }

    if (mounted) {
      _totalPenjualan.value = tempTotalPenjualan;
      _totalBarangTerjual.value = tempTotalBarangTerjual;
      _penjualanPercentage.value = percentageChange;
    }
}

void _calculatePembelianStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
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

    final previousData = await _getPreviousMonthData(_selectedMonth);
    final previousPembelian = previousData['pembelian'] ?? 0;
    
    double percentageChange = 0;
    if (previousPembelian > 0 && tempTotalPembelian > 0) {
      percentageChange = ((tempTotalPembelian - previousPembelian) / previousPembelian) * 100;
    }

    if (mounted) {
      _totalPembelian.value = tempTotalPembelian;
      _pembelianPercentage.value = percentageChange;
    }
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
      // Reset all values
      _totalPenjualan.value = 0;
      _totalPembelian.value = 0;
      _totalBarangTerjual.value = 0;
      _penjualanPercentage.value = 0;
      _pembelianPercentage.value = 0;
      _profitPercentage.value = 0;
      _initializeData();
    });
  }
}
  @override
 Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF080C67), Color(0xFF1A237E)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Laporan',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      _buildModernMonthPicker(),
                    ],
                  ),
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildModernStatisticsCards(),
                      const SizedBox(height: 24),
                      _buildProfitSection(),
                      const SizedBox(height: 24), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildModernMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF080C67),
            ),
            child: DropdownButton<String>(
              value: _selectedMonth,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
              items: _buildMonthDropdownItems(),
              onChanged: _onMonthChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildModernStatisticsCards() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _penjualanStream,
      builder: (context, penjualanSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _pembelianStream,
          builder: (context, pembelianSnapshot) {
            if (penjualanSnapshot.hasData) {
              _calculatePenjualanStats(penjualanSnapshot.data!.docs);
            }
            if (pembelianSnapshot.hasData) {
              _calculatePembelianStats(pembelianSnapshot.data!.docs);
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildModernStatCard(
                      'Total Penjualan',
                      _totalPenjualan,
                      Icons.trending_up_rounded,
                      const Color(0xFF4CAF50),
                      isPositive: true,
                      percentageNotifier: _penjualanPercentage,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernStatCard(
                      'Total Pembelian',
                      _totalPembelian,
                      Icons.trending_down_rounded,
                      const Color(0xFFE53935),
                      isPositive: false,
                      percentageNotifier: _pembelianPercentage,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ValueListenableBuilder<int>(
                      valueListenable: _totalBarangTerjual,
                      builder: (context, value, _) => _buildModernStatCard(
                        'Jumlah Terjual',
                        ValueNotifier(value.toDouble()),
                        Icons.inventory_2_rounded,
                        const Color(0xFF1976D2),
                        isCount: true,
                      ),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProfitStatCard()),
                  ],
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
 Widget _buildModernStatCard(
    String title,
    ValueNotifier<double> value,
    IconData icon,
    Color color, {
    bool isCount = false,
    bool isPositive = true,
    ValueNotifier<double>? percentageNotifier, // Tambah parameter untuk persentase
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<double>(
            valueListenable: value,
            builder: (context, val, _) => Text(
              isCount
                  ? val.toInt().toString()
                  : NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(val),
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isCount && percentageNotifier != null) ...[
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: percentageNotifier,
              builder: (context, percentage, _) {
                final isPositiveChange = percentage >= 0;
                final displayColor = isPositiveChange
                    ? const Color(0xFF4CAF50)  // Warna hijau untuk positif
                    : const Color(0xFFE53935);  // Warna merah untuk negatif
                    
                return Row(
                  children: [
                    Icon(
                      isPositiveChange
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: displayColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // Tambah tanda + untuk nilai positif
                      '${isPositiveChange ? "+" : ""}${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: displayColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildProfitStatCard() {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _penjualanStream,
    builder: (context, penjualanSnapshot) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pembelianStream,
        builder: (context, pembelianSnapshot) {
          double profit = _totalPenjualan.value - _totalPembelian.value;
          final isPositive = profit >= 0;
          final color = isPositive ? const Color(0xFF9C27B0) : const Color(0xFFFF7043);
          
          return _buildModernStatCard(
            'Profit',
            ValueNotifier(profit.abs()),
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color,
            isPositive: isPositive,
          );
        },
      );
    },
  );
}
 Widget _buildProfitSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profit Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF080C67),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080C67).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Monthly',
                      style: TextStyle(
                        color: Color(0xFF080C67),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_penjualanStream != null && _pembelianStream != null)
              SizedBox(
                height: 300,
                child: ProfitReportWidget(
                  penjualanStream: _penjualanStream!,
                  pembelianStream: _pembelianStream!,
                  selectedMonth: _selectedMonth,
                ),
              ),
          ],
        ),
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
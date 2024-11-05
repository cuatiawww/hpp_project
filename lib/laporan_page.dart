import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Use ValueNotifier instead of setState for statistics
  final ValueNotifier<double> _totalPenjualan = ValueNotifier(0);
  final ValueNotifier<double> _totalPembelian = ValueNotifier(0);
  final ValueNotifier<int> _totalBarangTerjual = ValueNotifier(0);
  
  Stream<QuerySnapshot<Map<String, dynamic>>>? _penjualanStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _pembelianStream;

  @override
 void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  
  // Inisialisasi tanggal
  final now = DateTime.now();
  _selectedMonth = DateFormat('yyyy-MM').format(now);
  
  // Inisialisasi periode
  final startDate = '$_selectedMonth-01';
  final date = DateTime.parse(startDate);
  final endDate = DateTime(date.year, date.month + 1, 0);
  final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

  // Set up streams
  _penjualanStream = _db.getLaporanPenjualanStream(startDate, endDateStr);
  _pembelianStream = _db.getLaporanPembelianStream(startDate, endDateStr);

  // Langsung ambil data awal
  _loadInitialData();
}
void _loadInitialData() async {
  try {
    final startDate = '$_selectedMonth-01';
    final date = DateTime.parse(startDate);
    final endDate = DateTime(date.year, date.month + 1, 0);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // Ambil data penjualan
    final penjualanDocs = await _db.getLaporanPenjualanStream(startDate, endDateStr).first;
    if (penjualanDocs.docs.isNotEmpty) {
      _calculatePenjualanStats(penjualanDocs.docs);
    }

    // Ambil data pembelian
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

  // Load data setelah stream diinisialisasi
  _loadInitialData();
}
  void _calculatePenjualanStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (!mounted) return;
    
    double tempTotalPenjualan = 0;
    int tempTotalBarangTerjual = 0;

    for (var doc in docs) {
      final data = doc.data();
      if (data['tanggal'] != null && data['tanggal'].startsWith(_selectedMonth)) {
        final hargaJual = (data['hargaJual'] as num?)?.toDouble() ?? 0;
        final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
        tempTotalPenjualan += (hargaJual * jumlah);
        tempTotalBarangTerjual += jumlah;
      }
    }

    _totalPenjualan.value = tempTotalPenjualan;
    _totalBarangTerjual.value = tempTotalBarangTerjual;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF080C67),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF080C67),
              tabs: const [
                Tab(text: 'Report Penjualan'),
                Tab(text: 'Report Pembelian'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPenjualanTab(),
                  _buildPembelianTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleAndDatePicker(),
          const SizedBox(height: 16),
          _buildStatisticsCards(),
        ],
      ),
    );
  }

  Widget _buildTitleAndDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Laporan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildMonthPicker(),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedMonth,
            underline: Container(),
            items: List.generate(12, (index) {
              final date = DateTime.now().subtract(Duration(days: 30 * index));
              final value = DateFormat('yyyy-MM').format(date);
              return DropdownMenuItem(
                value: value,
                child: Text(
                  DateFormat('MMMM yyyy').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
            onChanged: (String? newValue) {
              if (newValue != null && mounted) {
                setState(() {
                  _selectedMonth = newValue;
                  _initializeStreams();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.3,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _totalPenjualan,
              builder: (context, value, _) => _buildStatCard(
                'Total Penjualan',
                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(value),
                Icons.arrow_upward,
                Colors.green,
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _totalPembelian,
              builder: (context, value, _) => _buildStatCard(
                'Total Pembelian',
                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(value),
                Icons.arrow_downward,
                Colors.red,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _totalBarangTerjual,
              builder: (context, value, _) => _buildStatCard(
                'Barang Terjual',
                value.toString(),
                Icons.inventory,
                Colors.blue,
              ),
            ),
            ValueListenableBuilder<double>(
  valueListenable: _totalPenjualan,
  builder: (context, penjualan, _) {
    return ValueListenableBuilder<double>(
      valueListenable: _totalPembelian,
      builder: (context, pembelian, _) {
        return _buildStatCard(
          'Profit',
          NumberFormat.currency(
            locale: 'id',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(penjualan - pembelian),
          Icons.trending_up,
          Colors.purple,
        );
      },
    );
  },
),
          ],
        );
      },
    );
  }

  Widget _buildPenjualanTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _penjualanStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada data untuk bulan ini'));
        }

        final docs = snapshot.data!.docs;
        _calculatePenjualanStats(docs);

        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          return data['tanggal'] != null && data['tanggal'].startsWith(_selectedMonth);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('Tidak ada data untuk bulan ini'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: _buildTransactionList(filteredDocs, true),
        );
      },
    );
  }

  Widget _buildPembelianTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pembelianStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada data untuk bulan ini'));
        }

        final docs = snapshot.data!.docs;
        _calculatePembelianStats(docs);

        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          return data['Tanggal'] != null && data['Tanggal'].startsWith(_selectedMonth);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('Tidak ada data untuk bulan ini'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: _buildTransactionList(filteredDocs, false),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<QueryDocumentSnapshot<Map<String, dynamic>>> documents, bool isPenjualan) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final data = documents[index].data();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              isPenjualan ? data['namaBarang'] ?? '' : data['Name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipe: ${isPenjualan ? data['tipe'] : data['Type']}'),
                Text('Jumlah: ${isPenjualan ? data['jumlah'] : data['Jumlah']} ${data['satuan'] ?? ''}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(isPenjualan ? data['total'] : (data['Jumlah'] * data['Price'])),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  isPenjualan ? data['tanggal'] ?? '' : data['Tanggal'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
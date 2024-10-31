import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_calculation_page.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/input_pers_awal.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pembelian.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';

class PersAwal extends StatefulWidget {
  const PersAwal({super.key});

  @override
  State<PersAwal> createState() => _PersAwalState();
}

class _PersAwalState extends State<PersAwal> with SingleTickerProviderStateMixin {
  final List<Tab> _myTabs = [
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory),
          SizedBox(width: 8),
          Text('P. Awal'),
        ],
      ),
    ),
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart),
          SizedBox(width: 8),
          Text('Pembelian'),
        ],
      ),
    ),
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2),
          SizedBox(width: 8),
          Text('P. Akhir'),
        ],
      ),
    ),
  ];

  late TabController _tabController;
  Stream<QuerySnapshot>? _persAwalStream;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final List<String> _months = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _myTabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    _generateMonths();
    await _loadData();
    setState(() => _isLoading = false);
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  Future<void> _loadData() async {
    _persAwalStream = DatabaseMethods().getBarangDetails();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTable() {
  return StreamBuilder<QuerySnapshot>(
    stream: _persAwalStream,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text(
            "Tidak ada data barang yang ditemukan.",
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      // Filter documents for selected month and get the earliest entry for each item
      Map<String, DocumentSnapshot> earliestEntries = {};
      
      for (var doc in snapshot.data!.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey("Tanggal")) {
          String docDate = data["Tanggal"];
          String docMonth = docDate.substring(0, 7);
          
          if (docMonth == _selectedMonth) {
            String itemKey = "${data['Name']}_${data['Tipe']}";
            
            if (!earliestEntries.containsKey(itemKey)) {
              earliestEntries[itemKey] = doc;
            } else {
              // Compare dates and keep the earliest entry
              DateTime currentDate = DateTime.parse(docDate);
              DateTime existingDate = DateTime.parse(
                (earliestEntries[itemKey]!.data() as Map<String, dynamic>)['Tanggal']
              );
              
              if (currentDate.isBefore(existingDate)) {
                earliestEntries[itemKey] = doc;
              }
            }
          }
        }
      }

      List<DocumentSnapshot> filteredDocs = earliestEntries.values.toList();

      if (filteredDocs.isEmpty) {
        return Column(
          children: [
            _buildMonthDropdown(),
            const Expanded(
              child: Center(
                child: Text(
                  "Tidak ada data untuk bulan yang dipilih.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          _buildMonthDropdown(),
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey[100],
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Nama Barang",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Tipe",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Jumlah Awal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Satuan",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Harga",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Actions",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: filteredDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data["Name"] ?? "Nama tidak ada";
                      String type = data["Tipe"] ?? "Tipe tidak ada";
                      int jumlah = data["Jumlah"] ?? 0;
                      int price = data["Price"] ?? 0;
                      String satuan = data["Satuan"] ?? "Satuan tidak ada";
                      int total = jumlah * price;

                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(type)),
                          DataCell(Text(jumlah.toString())),
                          DataCell(Text(satuan)),
                          DataCell(Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(price),
                          )),
                          DataCell(Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(total),
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editBarangDetail(doc),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBarang(doc),
                                tooltip: 'Hapus',
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  Widget _buildMonthDropdown() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 16),
            const Text(
              "Filter Bulan:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMonth,
                items: _months.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(
                      DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedMonth = newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBarang(DocumentSnapshot doc) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Anda yakin ingin menghapus barang ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await DatabaseMethods().deleteBarangDetail(doc.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Barang berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _loadData());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus barang: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editBarangDetail(DocumentSnapshot ds) {
    final nameController = TextEditingController(text: ds["Name"]);
    final priceController = TextEditingController(text: ds["Price"].toString());
    final jumlahController = TextEditingController(text: ds["Jumlah"].toString());
    final tipeController = TextEditingController(text: ds["Tipe"] ?? "");

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Barang"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditField(
                "Nama Barang",
                nameController,
                TextInputType.text,
              ),
              const SizedBox(height: 16),
              _buildEditField(
                "Harga per Pcs",
                priceController,
                TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildEditField(
                "Jumlah",
                jumlahController,
                TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildEditField(
                "Tipe",
                tipeController,
                TextInputType.text,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseMethods().updateBarangDetail(
                  ds.id,
                  {
                    "Name": nameController.text,
                    "Price": int.parse(priceController.text),
                    "Jumlah": int.parse(jumlahController.text),
                    "Tipe": tipeController.text,
                  },
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Barang berhasil diupdate"),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _loadData());
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal mengupdate barang: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Masukkan $label',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: _myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'Perusahaan Dagang',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorPadding: const EdgeInsets.all(5),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: _myTabs,
            ),
          ),
          backgroundColor: const Color(0xFF080C67),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTable(),
            const PembelianPage(),
            PersAkhirPage(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'add_button',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InputPersAwal()),
                );
              },
              backgroundColor: const Color(0xFF080C67),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'calculate_button',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HPPCalculationPage()),
                );
              },
              backgroundColor: const Color(0xFF080C67),
              icon: const Icon(Icons.calculate),
              label: const Text(
                'Hitung HPP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
  // ignore_for_file: unused_field

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:hpp_project/service/database.dart';
  import 'package:intl/intl.dart';

  class PersAkhirPage extends StatefulWidget {
    const PersAkhirPage({super.key});

    @override
    _PersAkhirPageState createState() => _PersAkhirPageState();
  }

  class _PersAkhirPageState extends State<PersAkhirPage> {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    Stream<QuerySnapshot>? _barangStream;
    Stream<QuerySnapshot>? _pembelianStream;
    String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> _months = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _persediaanData = {};
    // Add a key for forcing refresh
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    // Add state to force rebuild
    bool _forceRebuild = false;

    @override
  void initState() {
    super.initState();
    _generateMonths();
    _loadData();
  }
  void _generateMonths() {
    _months = DatabaseMethods().generateMonthRange();
  }

    void _loadInitialData() {
      setState(() {
        // Update the streams
        _barangStream = DatabaseMethods().getBarangDetails();
        _pembelianStream = DatabaseMethods().getPembelianDetails();
        // Toggle rebuild flag
        _forceRebuild = !_forceRebuild;
      });
    }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseMethods().getPersediaanAkhir(_selectedMonth);
      setState(() {
        _persediaanData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memuat data: $e')),
      );
    }
  }
     Widget _buildMonthFilter() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF080C67),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: _months.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(
                    DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMonth = value);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
    Future<void> _refreshData() async {
      // Clear existing streams
      setState(() {
        _barangStream = null;
        _pembelianStream = null;
      });
      
      // Wait a bit to ensure clean slate
      await Future.delayed(Duration(milliseconds: 100));
      
      // Reload data
      _loadInitialData();
    }

   Widget _buildDataTable() {
  return Container(
    margin: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Color(0xFFEEF2FF)),
        columns: const [
          DataColumn(label: Text('Nama Barang')),
          DataColumn(label: Text('Tipe')),
          DataColumn(label: Text('Stok Tersedia')),
          DataColumn(label: Text('Satuan')),
          DataColumn(label: Text('Harga Terakhir')),
          DataColumn(label: Text('Total Nilai')),
        ],
        rows: _buildTableRows(_persediaanData),
      ),
    ),
  );
}

// Update method _buildTableRows untuk menggunakan data yang ada
List<DataRow> _buildTableRows(Map<String, Map<String, dynamic>> data) {
  return data.entries.map((entry) {
    final data = entry.value;
    final total = (data["Jumlah"] as int) * (data["Price"] as int);

    return DataRow(
      cells: [
        DataCell(Text(data["Name"])),
        DataCell(Text(data["Tipe"].toString())),
        DataCell(Text(data["Jumlah"].toString())),
        DataCell(Text(data["Satuan"])),
        DataCell(Text(NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(data["Price"]))),
        DataCell(Text(NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(total))),
      ],
    );
  }).toList();
}
    Widget _buildActionButtons(Map<String, dynamic> data, String key) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF080C67), size: 20),
            tooltip: 'Edit',
            onPressed: () => _editBarang(data, key),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            tooltip: 'Hapus',
            onPressed: () => _deleteBarang(data, key),
          ),
        ],
      );
  }

  Widget _buildMainContent() {
  return StreamBuilder<QuerySnapshot>(
    stream: DatabaseMethods().getBarangDetails(),
    builder: (context, barangSnapshot) {
      if (!barangSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final barangReference = _processBarangReference(barangSnapshot.data!.docs);

      return StreamBuilder<QuerySnapshot>(
        key: ValueKey(_forceRebuild),
        stream: _pembelianStream,
        builder: (context, pembelianSnapshot) {
          if (_pembelianStream == null || !pembelianSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
              ),
            );
          }

          final combinedData = _processCombinedData(
            barangSnapshot.data!.docs,
            pembelianSnapshot.data!.docs,
            barangReference,
          );

          if (combinedData.isEmpty) {
            return Column(
              children: [
                _buildMonthFilter(),
                Expanded(
                  child: Center(
                    child: Text(
                      "Tidak ada data untuk bulan yang dipilih.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildMonthFilter(),
              Expanded(child: _buildDataTable()), // Tidak perlu parameter
            ],
          );
        },
      );
    },
  );
}

    Map<String, Map<String, dynamic>> _processBarangReference(
      List<QueryDocumentSnapshot> docs,
    ) {
      final result = <String, Map<String, dynamic>>{};
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        result[doc.id] = {
          "Name": data["Name"] ?? "N/A",
          "Satuan": data["Satuan"] ?? "N/A",
          "docId": doc.id,
        };
      }
      return result;
    }

Map<String, Map<String, dynamic>> _processCombinedData(
  List<QueryDocumentSnapshot> barangDocs,
  List<QueryDocumentSnapshot> pembelianDocs,
  Map<String, Map<String, dynamic>> barangReference,
) {
  final combinedData = <String, Map<String, dynamic>>{};
  final selectedDate = DateTime.parse('${_selectedMonth}-01');
  
  // 1. Proses data persediaan awal (Barang)
  for (var doc in barangDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = DateTime.parse(data["CreatedAt"] ?? "2099-12-31"); // Default future date if not found
    
    // Hanya tambahkan barang jika tanggal pembuatannya sebelum atau sama dengan bulan yang dipilih
    if (!createdAt.isAfter(selectedDate)) {
      final key = '${doc.id}_${data["Tipe"] ?? "Default"}';
      combinedData[key] = _createBarangEntry(doc.id, data);
    }
  }

  // 2. Proses pembelian (menambah stok)
  for (var doc in pembelianDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final purchaseDate = DateTime.parse(data["Tanggal"]);
    
    // Hanya proses pembelian yang terjadi sebelum atau pada bulan yang dipilih
    if (!purchaseDate.isAfter(selectedDate)) {
      final barangId = data["BarangId"];
      final key = '${barangId}_${data["Type"]}';
      
      if (combinedData.containsKey(key)) {
        combinedData[key]!["Jumlah"] = (combinedData[key]!["Jumlah"] as int) + (data["Jumlah"] as int);
        // Update harga jika pembelian ini adalah yang terbaru
        if (data["Price"] != null) {
          combinedData[key]!["Price"] = data["Price"];
        }
      } else {
        combinedData[key] = {
          "id": barangId,
          "Name": data["Name"] ?? "N/A",
          "Satuan": data["Satuan"] ?? "N/A",
          "Jumlah": data["Jumlah"] ?? 0,
          "Price": data["Price"] ?? 0,
          "Tipe": data["Type"] ?? "Default",
          "isOriginal": false,
          "docId": doc.id,
        };
      }
    }
  }

  // 3. Proses penjualan (mengurangi stok)
  Future<void> processPenjualan() async {
    final penjualanSnapshot = await FirebaseFirestore.instance
      .collection("Users")
      .doc(DatabaseMethods().currentUserId)
      .collection("Penjualan")
      .where('tanggal', isLessThanOrEqualTo: '${_selectedMonth}-31')
      .get();

    for (var doc in penjualanSnapshot.docs) {
      final data = doc.data();
      final saleDate = DateTime.parse(data["tanggal"]);
      
      // Hanya proses penjualan yang terjadi sebelum atau pada bulan yang dipilih
      if (!saleDate.isAfter(selectedDate)) {
        final barangId = data["barangId"];
        final tipe = data["tipe"];
        final key = '${barangId}_$tipe';
        
        if (combinedData.containsKey(key)) {
          final currentStock = combinedData[key]!["Jumlah"] as int;
          final soldAmount = data["jumlah"] as int;
          combinedData[key]!["Jumlah"] = currentStock - soldAmount;
        }
      }
    }
  }

  // Panggil processPenjualan
  processPenjualan();

  // Filter out items with zero or negative stock
  combinedData.removeWhere((key, value) => (value["Jumlah"] as int) <= 0);

  return combinedData;
}

bool _isDocInSelectedMonth(Map<String, dynamic> data) {
  final tanggal = data["Tanggal"] ?? data["tanggal"];
  if (tanggal != null) {
    return tanggal.startsWith(_selectedMonth);
  }
  return false;
}

String _getNextMonthString() {
  final date = DateTime.parse('${_selectedMonth}-01');
  final nextMonth = DateTime(date.year, date.month + 1, 1);
  return DateFormat('yyyy-MM').format(nextMonth);
}

    Map<String, dynamic> _createBarangEntry(String id, Map<String, dynamic> data) {
      return {
        "id": id,
        "Name": data["Name"] ?? "N/A",
        "Satuan": data["Satuan"] ?? "N/A",
        "Jumlah": data["Jumlah"] ?? 0,
        "Price": data["Price"] ?? 0,
        "Tipe": data["Tipe"] ?? "Default",
        "isOriginal": true,
        "docId": id,
      };
    }

    void _updateCombinedData(
      Map<String, Map<String, dynamic>> combinedData,
      Map<String, List<String>> pembelianDocsMap,
      String key,
      QueryDocumentSnapshot doc,
      Map<String, dynamic> data,
      Map<String, Map<String, dynamic>> barangReference,
    ) {
      // Update pembelian docs list
      pembelianDocsMap.putIfAbsent(key, () => []).add(doc.id);

      if (combinedData.containsKey(key)) {
        // Update existing entry
        combinedData[key]!["Jumlah"] = (combinedData[key]!["Jumlah"] as int) + (data["Jumlah"] as int);
        if (data["Price"] != null) {
          combinedData[key]!["Price"] = data["Price"];
        }
      } else {
        // Create new entry
        final barangRef = barangReference[data["BarangId"]];
        combinedData[key] = {
          "id": data["BarangId"],
          "Name": barangRef?["Name"] ?? "N/A",
          "Satuan": barangRef?["Satuan"] ?? "N/A",
          "Jumlah": data["Jumlah"] ?? 0,
          "Price": data["Price"] ?? 0,
          "Tipe": data["Type"],
          "isOriginal": false,
          "docId": doc.id,
          "pembelianIds": pembelianDocsMap[key],
        };
      }
    }

    void _showMessage(String message, bool isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    //DATABASES

    Future<void> _editBarang(Map<String, dynamic> data, String key) async {
      final jumlahController = TextEditingController(text: data["Jumlah"].toString());

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Jumlah Barang",
            style: TextStyle(
              color: Color(0xFF080C67),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoField("Nama Barang", data['Name']),
              SizedBox(height: 12),
              _buildDialogInfoField("Tipe", data['Tipe']),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Jumlah",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF080C67),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: jumlahController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.numbers_rounded, color: Color(0xFF080C67), size: 20),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Batal",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF080C67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text("Simpan"),
            ),
          ],
        ),
      );

      if (result == true) {
        try {
          await _updateJumlah(data, int.parse(jumlahController.text));
          _showSuccess("Data berhasil diupdate");
          await _refreshData(); // Use the new refresh method
        } catch (e) {
          _showError("Gagal mengupdate data: $e");
        }
      }
  }

  Widget _buildDialogInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF080C67),
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }



  Future<void> _updateJumlah(Map<String, dynamic> data, int newJumlah) async {
  final userId = DatabaseMethods().currentUserId;
  
  try {
    if (data["isOriginal"] == true) {
      // Case 1: This is an original inventory entry
      await DatabaseMethods().updateBarangDetail(
        data["docId"],
        {"Jumlah": newJumlah},
      );
    } else {
      // Case 2: This is a combined entry from purchases
      final barangId = data["id"];
      
      // First, get all related purchase documents
      final pembelianSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("Pembelian")
          .where("BarangId", isEqualTo: barangId)
          .where("Type", isEqualTo: data["Tipe"])
          .where("Tanggal", isGreaterThanOrEqualTo: "${_selectedMonth}-01")
          .where("Tanggal", isLessThan: "${_getNextMonthString()}")
          .get();

      // Get the original inventory document for this month
      final barangSnapshot = await _db
          .collection("Users")
          .doc(userId)
          .collection("Barang")
          .doc(barangId)
          .get();

      if (!barangSnapshot.exists) {
        throw Exception("Barang not found");
      }

      final barangData = barangSnapshot.data()!;
      final originalJumlah = barangData["Jumlah"] ?? 0;

      // Calculate total from purchases
      int totalPembelian = 0;
      for (var doc in pembelianSnapshot.docs) {
        totalPembelian += (doc.data()["Jumlah"] as int);
      }

      // Calculate the current total (original + purchases)
      final currentTotal = originalJumlah + totalPembelian;

      // Calculate the difference ratio for distribution
      final ratio = newJumlah / currentTotal;

      // Start a new batch operation
      final batch = _db.batch();

      // Update original inventory
      final newOriginalJumlah = (originalJumlah * ratio).round();
      batch.update(
        _db.collection("Users").doc(userId).collection("Barang").doc(barangId),
        {"Jumlah": newOriginalJumlah}
      );

      // Update each purchase document proportionally
      for (var doc in pembelianSnapshot.docs) {
        final currentPembelianJumlah = doc.data()["Jumlah"] as int;
        final newPembelianJumlah = (currentPembelianJumlah * ratio).round();
        
        batch.update(doc.reference, {"Jumlah": newPembelianJumlah});
      }

      // Commit all updates
      await batch.commit();
    }

    // Refresh the data after update
    await _refreshData();
  } catch (e) {
    print("Error in _updateJumlah: $e");
    throw e;
  }
}
  
  Future<void> _deleteBarang(Map<String, dynamic> data, String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Konfirmasi Hapus",
          style: TextStyle(
            color: Color(0xFF080C67),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Apakah Anda yakin ingin menghapus barang ini?"),
            SizedBox(height: 16),
            _buildDialogInfoField("Nama Barang", data['Name']),
            SizedBox(height: 12),
            _buildDialogInfoField("Tipe", data['Tipe']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Hapus"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
        try {
          final userId = DatabaseMethods().currentUserId;
          if (data["isOriginal"] == true) {
            await DatabaseMethods().deleteBarangDetail(data["docId"]);
          } else {
            final pembelianIds = data["pembelianIds"] as List<String>?;
            if (pembelianIds != null) {
              await Future.wait(
                pembelianIds.map((id) => _db
                    .collection("Users")
                    .doc(userId)
                    .collection("Pembelian")
                    .doc(id)
                    .delete()),
              );
            }
          }
          _showSuccess("Data berhasil dihapus");
          await _refreshData(); // Use the new refresh method
        } catch (e) {
          _showError("Gagal menghapus data: $e");
        }
      }
    }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Persediaan Akhir',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF080C67),
                Color(0xFF1E23A7),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildMonthFilter(),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
                  ),
                )
              else if (_persediaanData.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Tidak ada data persediaan untuk bulan ini',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                _buildDataTable(),
            ],
          ),
        ),
      ),
    );
  }
}
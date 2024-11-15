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
    final List<String> _months = [];
    // Add a key for forcing refresh
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    // Add state to force rebuild
    bool _forceRebuild = false;

    @override
    void initState() {
      super.initState();
      _generateMonths();
      _loadInitialData();
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

    void _generateMonths() {
      final now = DateTime.now();
      for (int i = 0; i < 12; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        _months.add(DateFormat('yyyy-MM').format(month));
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
          Text(
            "Filter Bulan:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF080C67),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedMonth,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded, 
                    color: Color(0xFF080C67)
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  items: _months.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(
                        DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
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

    Widget _buildDataTable(Map<String, Map<String, dynamic>> combinedData) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Data Persediaan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF080C67),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Color(0xFFEEF2FF)),
                headingTextStyle: TextStyle(
                  color: Color(0xFF080C67),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                columns: const [
                  DataColumn(label: Text("Nama Barang")),
                  DataColumn(label: Text("Tipe")),
                  DataColumn(label: Text("Jumlah")),
                  DataColumn(label: Text("Satuan")),
                  DataColumn(label: Text("Harga")),
                  DataColumn(label: Text("Total")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: _buildTableRows(combinedData),
              ),
            ),
          ],
        ),
      );
  }
    List<DataRow> _buildTableRows(Map<String, Map<String, dynamic>> combinedData) {
      return combinedData.entries.map((entry) {
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
            DataCell(_buildActionButtons(data, entry.key)),
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
                  Expanded(child: _buildDataTable(combinedData)),
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
    
    // First process all barang docs
    for (var doc in barangDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (_isDocInSelectedMonth(data)) {
        // Only include non-pembelian items in initial processing
        if (data['isFromPembelian'] != true) {
          final key = '${doc.id}_${data["Tipe"] ?? "Default"}';
          combinedData[key] = _createBarangEntry(doc.id, data);
        }
      }
    }

    // Then process all pembelian docs
    for (var doc in pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (_isDocInSelectedMonth(data)) {
        final barangId = data["BarangId"];
        final key = '${barangId}_${data["Type"]}';
        
        // If this barang already exists in combinedData
        if (combinedData.containsKey(key)) {
          // Update existing entry
          combinedData[key]!["Jumlah"] = (combinedData[key]!["Jumlah"] as int) + (data["Jumlah"] as int);
          if (data["Price"] != null) {
            combinedData[key]!["Price"] = data["Price"];
          }
        } else {
          // Create new entry
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

    return combinedData;
  }
    bool _isDocInSelectedMonth(Map<String, dynamic> data) {
      if (data.containsKey("Tanggal")) {
        final docMonth = data["Tanggal"].substring(0, 7);
        return docMonth == _selectedMonth;
      }
      return false;
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
      
      if (data["isOriginal"] == true) {
        await DatabaseMethods().updateBarangDetail(
          data["docId"],
          {"Jumlah": newJumlah},
        );
      } else {
        final pembelianIds = data["pembelianIds"] as List<String>?;
        if (pembelianIds != null) {
          final newJumlahPerDoc = newJumlah ~/ pembelianIds.length;
          await Future.wait(
            pembelianIds.map((id) => _db
                .collection("Users")
                .doc(userId)
                .collection("Pembelian")
                .doc(id)
                .update({"Jumlah": newJumlahPerDoc})),
          );
        }
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
          key: _refreshIndicatorKey,
          onRefresh: _refreshData, // Use the new refresh method
          child: _buildMainContent(),
        ),
    );
  }
  }
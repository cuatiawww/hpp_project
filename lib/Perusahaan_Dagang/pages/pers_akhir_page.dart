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

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _loadInitialData();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  void _loadInitialData() {
    _barangStream = DatabaseMethods().getBarangDetails();
    _pembelianStream = DatabaseMethods().getPembelianDetails();
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

  Widget _buildDataTable(Map<String, Map<String, dynamic>> combinedData) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(
                label: Text("Nama Barang", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Jumlah", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Satuan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Harga", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            rows: _buildTableRows(combinedData),
          ),
        ),
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
          icon: const Icon(Icons.edit, color: Colors.blue),
          tooltip: 'Edit',
          onPressed: () => _editBarang(data, key),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
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
          stream: DatabaseMethods().getPembelianDetails(),
          builder: (context, pembelianSnapshot) {
            if (!pembelianSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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
    final pembelianDocsMap = <String, List<String>>{};

    // Process barang data
    for (var doc in barangDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (_isDocInSelectedMonth(data)) {
        final key = '${doc.id}_${data["Tipe"] ?? "Default"}';
        combinedData[key] = _createBarangEntry(doc.id, data);
      }
    }

    // Process pembelian data
    for (var doc in pembelianDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (_isDocInSelectedMonth(data)) {
        final key = '${data["BarangId"]}_${data["Type"]}';
        _updateCombinedData(
          combinedData,
          pembelianDocsMap,
          key,
          doc,
          data,
          barangReference,
        );
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
        title: const Text("Edit Jumlah Barang"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama: ${data['Name']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Tipe: ${data['Tipe']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: jumlahController,
              decoration: const InputDecoration(
                labelText: "Jumlah",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _updateJumlah(data, int.parse(jumlahController.text));
        _showMessage("Data berhasil diupdate", false);
        _loadInitialData();
      } catch (e) {
        _showMessage("Gagal mengupdate data: $e", true);
      }
    }
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
      title: const Text("Konfirmasi Hapus"),
      content: const Text("Anda yakin ingin menghapus barang ini?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Hapus"),
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
      _showMessage("Data berhasil dihapus", false);
      _loadInitialData();
    } catch (e) {
      _showMessage("Gagal menghapus data: $e", true);
    }
  }
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
      onRefresh: () async {
        _loadInitialData();
      },
      child: _buildMainContent(),
    ),
  );
}
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan_Dagang/notification/service/notification_service.dart';
// import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_calculation_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/input_pers_awal.dart';
// import 'package:hpp_project/perusahaan_dagang/pages/pembelian_page.dart';
// import 'package:hpp_project/perusahaan_dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/service/database.dart';
import 'package:intl/intl.dart';

class PersAwal extends StatefulWidget {
  const PersAwal({super.key});

  @override
  State<PersAwal> createState() => _PersAwalState();
}

class _PersAwalState extends State<PersAwal> {
  Stream<QuerySnapshot>? _persAwalStream;
   String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> _months = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    _months = [];
    
    // 6 bulan sebelumnya
    for (int i = 6; i >= 1; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
    
    // Bulan sekarang
    _months.add(DateFormat('yyyy-MM').format(now));
    
    // 6 bulan kedepan
    for (int i = 1; i <= 6; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      _months.add(DateFormat('yyyy-MM').format(month));
    }
  }

  Future<void> _loadData() async {
    _persAwalStream = DatabaseMethods().getBarangDetails();
  }

Widget _buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _persAwalStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080C67)),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  "Tidak ada data barang yang ditemukan.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter documents berdasarkan bulan yang dipilih
         Map<String, DocumentSnapshot> filteredEntries = {};
        
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          
          if (data.containsKey("Tanggal")) {
            String docDate = data["Tanggal"];
            String docMonth = docDate.substring(0, 7);
            
            if (docMonth == _selectedMonth) {
              String itemKey = "${data['Name']}_${data['Tipe']}";
              filteredEntries[itemKey] = doc;
            }
          }
        }

        List<DocumentSnapshot> filteredDocs = filteredEntries.values.toList();
        
        // for (var doc in snapshot.data!.docs) {
        //   var data = doc.data() as Map<String, dynamic>;
          
        //   // Skip jika data berasal dari pembelian
        //   if (data['isFromPembelian'] == true) {
        //     continue;
        //   }
          
        //   if (data.containsKey("Tanggal")) {
        //     String docDate = data["Tanggal"];
        //     String docMonth = docDate.substring(0, 7);
            
        //     if (docMonth == _selectedMonth) {
        //       String itemKey = "${data['Name']}_${data['Tipe']}";
              
        //       if (!filteredEntries.containsKey(itemKey)) {
        //         filteredEntries[itemKey] = doc;
        //       } else {
        //         DateTime currentDate = DateTime.parse(docDate);
        //         DateTime existingDate = DateTime.parse(
        //           (filteredEntries[itemKey]!.data() as Map<String, dynamic>)['Tanggal']
        //         );
                
        //         if (currentDate.isBefore(existingDate)) {
        //           filteredEntries[itemKey] = doc;
        //         }
        //       }
        //     }
        //   }
        // }

        // List<DocumentSnapshot> filteredDocs = filteredEntries.values.toList();

        if (filteredDocs.isEmpty) {
          return Column(
            children: [
              _buildMonthDropdown(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Tidak ada data untuk bulan yang dipilih.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
              child: Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Color(0xFFEEF2FF),
                      ),
                      columns: const [
                        DataColumn(label: Text("Nama Barang")),
                        DataColumn(label: Text("Tipe")),
                        DataColumn(label: Text("Jumlah Awal")),
                        DataColumn(label: Text("Satuan")),
                        DataColumn(label: Text("Harga")),
                        DataColumn(label: Text("Total")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: filteredDocs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(data["Name"] ?? "Nama tidak ada")),
                            DataCell(Text(data["Tipe"] ?? "Tipe tidak ada")),
                            DataCell(Text(data["Jumlah"]?.toString() ?? "0")),
                            DataCell(Text(data["Satuan"] ?? "Satuan tidak ada")),
                            DataCell(Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(data["Price"] ?? 0),
                            )),
                            DataCell(Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format((data["Jumlah"] ?? 0) * (data["Price"] ?? 0)),
                            )),
                            DataCell(_buildActionButtons(doc)),
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


Widget _buildActionButtons(DocumentSnapshot doc) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _editBarangDetail(doc),
          child: Icon(
            Icons.edit_rounded,
            color: Color(0xFF080C67),
            size: 20,
          ),
        ),
      ),
      SizedBox(width: 8),
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _deleteBarang(doc),
          child: Icon(
            Icons.delete_rounded,
            color: Colors.red[400],
            size: 20,
          ),
        ),
      ),
    ],
  );
}
  
  Widget _buildMonthDropdown() {
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

Future<void> _editBarangDetail(DocumentSnapshot ds) {
  final nameController = TextEditingController(text: ds["Name"]);
  final priceController = TextEditingController(text: ds["Price"].toString());
  final jumlahController = TextEditingController(text: ds["Jumlah"].toString());
  final tipeController = TextEditingController(text: ds["Tipe"] ?? "");

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: EdgeInsets.all(24),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Color(0xFF080C67),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            "Edit Barang",
            style: TextStyle(
              color: Color(0xFF080C67),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField(
              "Nama Barang",
              nameController,
              TextInputType.text,
              Icons.inventory_2_rounded,
            ),
            SizedBox(height: 16),
            _buildEditField(
              "Harga per Unit",
              priceController,
              TextInputType.number,
              Icons.attach_money_rounded,
            ),
            SizedBox(height: 16),
            _buildEditField(
              "Jumlah",
              jumlahController,
              TextInputType.number,
              Icons.numbers_rounded,
            ),
            SizedBox(height: 16),
            _buildEditField(
              "Tipe",
              tipeController,
              TextInputType.text,
              Icons.category_rounded,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Batal",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF080C67),
                Color(0xFF1E23A7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF080C67).withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
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

                  // Menambahkan notifikasi update
                  await addPersediaanAwalNotification(
                    namaBarang: nameController.text,
                    jumlah: int.parse(jumlahController.text),
                    satuan: ds["Satuan"],
                    action: 'update',
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text("Barang berhasil diupdate"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  setState(() => _loadData());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text("Gagal mengupdate barang: ${e.toString()}"),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Update",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteBarang(DocumentSnapshot doc) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.delete_rounded,
              color: Colors.red[400],
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            "Konfirmasi Hapus",
            style: TextStyle(
              color: Colors.red[400],
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Text(
        "Anda yakin ingin menghapus barang ini?",
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "Batal",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                Navigator.pop(context, true);
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  await DatabaseMethods().deleteBarangDetail(doc.id);

                    // Menambahkan notifikasi delete
                    await addPersediaanAwalNotification(
                      namaBarang: data['Name'],
                      jumlah: data['Jumlah'],
                      satuan: data['Satuan'],
                      action: 'delete',
                    );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text("Barang berhasil dihapus"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  setState(() => _loadData());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text("Gagal menghapus barang: ${e.toString()}"),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Hapus",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEditField(
  String label,
  TextEditingController controller,
  TextInputType keyboardType,
  IconData icon,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Color(0xFF080C67),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
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
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Color(0xFF080C67),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Persediaan Awal',
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
    body: Container(
      color: Color(0xFFF8FAFC),
      child: _buildTable(),
    ),
    floatingActionButton: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF080C67),
            Color(0xFF1E23A7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF080C67).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InputPersAwal()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    ),
  );
}
}
// class HPPData {
//   final String startDate;
//   final String endDate;
//   final double persediaanAwal;
//   final double pembelian;
//   final double bebanAngkut;
//   final double returPembelian;
//   final double potonganPembelian;
//   final double persediaanAkhir;
//   final double pembelianBersih;
//   final double barangTersedia;
//   final double hpp;

//   HPPData({
//     required this.startDate,
//     required this.endDate,
//     required this.persediaanAwal,
//     required this.pembelian,
//     required this.bebanAngkut,
//     required this.returPembelian,
//     required this.potonganPembelian,
//     required this.persediaanAkhir,
//   }) : pembelianBersih = pembelian + bebanAngkut - returPembelian - potonganPembelian,
//        barangTersedia = persediaanAwal + (pembelian + bebanAngkut - returPembelian - potonganPembelian),
//        hpp = (persediaanAwal + (pembelian + bebanAngkut - returPembelian - potonganPembelian)) - persediaanAkhir;

//   factory HPPData.empty() {
//     return HPPData(
//       startDate: '',
//       endDate: '',
//       persediaanAwal: 0,
//       pembelian: 0,
//       bebanAngkut: 0,
//       returPembelian: 0,
//       potonganPembelian: 0,
//       persediaanAkhir: 0,
//     );
//   }

//   factory HPPData.fromMap(Map<String, dynamic> map) {
//     return HPPData(
//       startDate: map['startDate'] ?? '',
//       endDate: map['endDate'] ?? '',
//       persediaanAwal: map['persediaanAwal']?.toDouble() ?? 0,
//       pembelian: map['pembelian']?.toDouble() ?? 0,
//       bebanAngkut: map['bebanAngkut']?.toDouble() ?? 0,
//       returPembelian: map['returPembelian']?.toDouble() ?? 0,
//       potonganPembelian: map['potonganPembelian']?.toDouble() ?? 0,
//       persediaanAkhir: map['persediaanAkhir']?.toDouble() ?? 0,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'startDate': startDate,
//       'endDate': endDate,
//       'persediaanAwal': persediaanAwal,
//       'pembelian': pembelian,
//       'bebanAngkut': bebanAngkut,
//       'returPembelian': returPembelian,
//       'potonganPembelian': potonganPembelian,
//       'pembelianBersih': pembelianBersih,
//       'barangTersedia': barangTersedia,
//       'persediaanAkhir': persediaanAkhir,
//       'hpp': hpp,
//     };
//   }
// }
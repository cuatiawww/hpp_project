// hpp_widgets.dart
import 'package:flutter/material.dart';
import 'package:hpp_project/Perusahaan%20Dagang/pages/hpp_model.dart';
import 'package:intl/intl.dart';

class HPPCalculationWidget extends StatelessWidget {
  final HPPData hppData;
  final NumberFormat currencyFormat;

  const HPPCalculationWidget({
    Key? key,
    required this.hppData,
    required this.currencyFormat,
  }) : super(key: key);

  Widget _buildCalculationRow(
    BuildContext context,
    String label, 
    double value, {
    bool isSubtotal = false,
    bool isTotal = false,
    bool isNegative = false,
  }) {
    final textStyle = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Theme.of(context).primaryColor : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isNegative 
                ? '-${currencyFormat.format(value)}' 
                : currencyFormat.format(value),
              style: textStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Perhitungan HPP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildCalculationRow(
          context,
          'Persediaan Awal',
          hppData.persediaanAwal,
        ),
        _buildCalculationRow(
          context,
          'Pembelian',
          hppData.pembelian,
        ),
        _buildCalculationRow(
          context,
          'Beban Angkut Pembelian',
          hppData.bebanAngkut,
        ),
        _buildCalculationRow(
          context,
          'Retur Pembelian',
          hppData.returPembelian,
          isNegative: true,
        ),
        _buildCalculationRow(
          context,
          'Potongan Pembelian',
          hppData.potonganPembelian,
          isNegative: true,
        ),
        const Divider(),
        _buildCalculationRow(
          context,
          'Pembelian Bersih',
          hppData.pembelianBersih,
          isSubtotal: true,
        ),
        const Divider(),
        _buildCalculationRow(
          context,
          'Barang Tersedia untuk Dijual',
          hppData.barangTersedia,
          isSubtotal: true,
        ),
        _buildCalculationRow(
          context,
          'Persediaan Akhir',
          hppData.persediaanAkhir,
          isNegative: true,
        ),
        const Divider(),
        _buildCalculationRow(
          context,
          'Harga Pokok Penjualan (HPP)',
          hppData.hpp,
          isTotal: true,
        ),
      ],
    );
  }
}
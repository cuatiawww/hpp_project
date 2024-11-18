import 'package:flutter/material.dart';
import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_model.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isTotal 
            ? Color(0xFFEEF2FF)
            : isSubtotal 
                ? Color(0xFFF8FAFC) 
                : Colors.white,
        borderRadius: isTotal ? BorderRadius.circular(12) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isTotal) ...[
                  Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFF080C67),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal || isSubtotal 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                    color: isTotal 
                        ? Color(0xFF080C67)
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isNegative 
                  ? '(${currencyFormat.format(value)})'
                  : currencyFormat.format(value),
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal || isSubtotal 
                    ? FontWeight.w600 
                    : FontWeight.normal,
                color: isTotal 
                    ? Color(0xFF080C67)
                    : isNegative 
                        ? Colors.red[700]
                        : Colors.grey[800],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.2),
      thickness: 1,
      height: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Persediaan Awal
        _buildCalculationRow(
          context,
          '1. Persediaan Awal',
          hppData.persediaanAwal,
        ),
        _buildDivider(),
        
        // Pembelian
        _buildCalculationRow(
          context,
          '2. Pembelian',
          hppData.pembelian,
        ),
        _buildDivider(),
        
        // Beban Angkut
        _buildCalculationRow(
          context,
          '3. Beban Angkut Pembelian',
          hppData.bebanAngkut,
        ),
        _buildDivider(),
        
        // Retur Pembelian
        _buildCalculationRow(
          context,
          '4. Retur Pembelian',
          hppData.returPembelian,
          isNegative: true,
        ),
        _buildDivider(),
        
        // Potongan Pembelian
        _buildCalculationRow(
          context,
          '5. Potongan Pembelian',
          hppData.potonganPembelian,
          isNegative: true,
        ),
        _buildDivider(),
        
        // Pembelian Bersih
        _buildCalculationRow(
          context,
          '6. Pembelian Bersih',
          hppData.pembelianBersih,
          isSubtotal: true,
        ),
        _buildDivider(),
        
        // Barang Tersedia
        _buildCalculationRow(
          context,
          '7. Barang Tersedia untuk Dijual',
          hppData.barangTersedia,
          isSubtotal: true,
        ),
        _buildDivider(),
        
        // Persediaan Akhir
        _buildCalculationRow(
          context,
          '8. Persediaan Akhir',
          hppData.persediaanAkhir,
          isNegative: true,
        ),
        _buildDivider(),
        
        SizedBox(height: 16),
        
        // HPP (Total)
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
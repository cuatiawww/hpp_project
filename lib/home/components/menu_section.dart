// lib/pages/home/components/menu_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/Perusahaan_Dagang/pages/penjualan_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pembelian_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_akhir_page.dart';
import 'package:hpp_project/perusahaan_dagang/pages/pers_awal_page.dart';
import 'package:hpp_project/perusahaan_dagang/hpp_calculation/hpp_calculation_page.dart';

class MenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 25) / 4;
              return Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  _buildMenuItem(Icons.add_circle, "Persediaan\nAwal", itemWidth,
                      onPressed: () {
                    Get.to(() => PersAwal());
                  }),
                  _buildMenuItem(Icons.shopping_cart, "Pembelian", itemWidth,
                      onPressed: () {
                    Get.to(() => PembelianPage());
                  }),
                  _buildMenuItem(Icons.point_of_sale, "Penjualan", itemWidth,
                      onPressed: () {
                    Get.to(() => PenjualanPage());
                  }),
                  _buildMenuItem(Icons.inventory_2, "Persediaan\nAkhir", itemWidth,
                      onPressed: () {
                    Get.to(() => PersAkhirPage());
                  }),
                ],
              );
            },
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => HPPCalculationPage());
              },
              icon: Icon(Icons.calculate, color: Colors.white),
              label: Text(
                'Hitung HPP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF080C67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, double itemWidth,
      {Function()? onPressed}) {
    return Container(
      width: itemWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(15),
              fixedSize: Size(50, 50),
              backgroundColor: Color(0xFF080C67),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
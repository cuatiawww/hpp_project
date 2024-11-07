// lib/pages/home/models/riwayat_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatItem extends StatelessWidget {
  final String title;
  final String description;
  final int price;
  final String type;
  final String date;

  const RiwayatItem({
    Key? key,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color and icon based on type
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case "Penjualan":
        typeColor = Colors.green;
        typeIcon = Icons.shopping_bag_outlined;
        break;
      case "Pembelian":
        typeColor = Colors.red;
        typeIcon = Icons.shopping_cart_outlined;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.inventory_outlined;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Rp ${NumberFormat('#,###').format(price)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
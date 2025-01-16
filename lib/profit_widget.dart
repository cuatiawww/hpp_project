import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfitReportWidget extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> penjualanStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> pembelianStream;
  final String selectedMonth;

  const ProfitReportWidget({
    Key? key,
    required this.penjualanStream,
    required this.pembelianStream,
    required this.selectedMonth,
  }) : super(key: key);

  @override
  State<ProfitReportWidget> createState() => _ProfitReportWidgetState();
}

class _ProfitReportWidgetState extends State<ProfitReportWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, Map<String, double>> weeklyData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _processData();
  }

  void _processData() {
    isLoading = true;
    weeklyData.clear();

    // Initialize weekly data structure
    for (int i = 1; i <= 4; i++) {
      weeklyData[i] = {
        'penjualan': 0,
        'pembelian': 0,
        'profit': 0,
      };
    }

    // Listen to both streams
    widget.penjualanStream.listen((penjualanSnapshot) {
      for (var doc in penjualanSnapshot.docs) {
        final data = doc.data();
        if (data['tanggal'] != null && data['tanggal'].startsWith(widget.selectedMonth)) {
          final date = DateTime.parse(data['tanggal']);
          final weekNumber = ((date.day - 1) ~/ 7) + 1;
          final total = (data['total'] as num).toDouble();
          
          weeklyData[weekNumber]?['penjualan'] = 
              (weeklyData[weekNumber]?['penjualan'] ?? 0) + total;
          _updateProfit(weekNumber);
        }
      }
      setState(() {});
    });

    widget.pembelianStream.listen((pembelianSnapshot) {
      for (var doc in pembelianSnapshot.docs) {
        final data = doc.data();
        if (data['Tanggal'] != null && data['Tanggal'].startsWith(widget.selectedMonth)) {
          final date = DateTime.parse(data['Tanggal']);
          final weekNumber = ((date.day - 1) ~/ 7) + 1;
          final total = (data['Price'] as num).toDouble() * (data['Jumlah'] as num).toDouble();
          
          weeklyData[weekNumber]?['pembelian'] = 
              (weeklyData[weekNumber]?['pembelian'] ?? 0) + total;
          _updateProfit(weekNumber);
        }
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  void _updateProfit(int weekNumber) {
    if (weeklyData.containsKey(weekNumber)) {
      weeklyData[weekNumber]!['profit'] = 
          weeklyData[weekNumber]!['penjualan']! - 
          weeklyData[weekNumber]!['pembelian']!;
    }
  }

  @override
 Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final double chartHeight = constraints.maxHeight * 0.5;
        final double tabHeight = 40.0;
        final double padding = 8.0;

        return Column(
          children: [
            // Tab Bar with fixed height
            SizedBox(
              height: tabHeight,
              child: _buildTabBar(),
            ),
            SizedBox(height: padding),
            
            // Charts section with flexible height
            Expanded(
              flex: 3, // Takes 3/4 of remaining space
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWeeklyBarChart(chartHeight),
                  _buildProfitLineChart(chartHeight),
                ],
              ),
            ),
            
            SizedBox(height: padding),
            
          ],
        );
      },
    );
  }
   Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF080C67),
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFEEF2FF),
        ),
        labelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'Weekly Analysis'),
          Tab(text: 'Profit Overview'),
        ],
      ),
    );
  }
   Widget _buildWeeklyBarChart(double height) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Profit Analysis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weeklyData.values
                    .expand((element) => [element['penjualan']!, element['pembelian']!, element['profit']!])
                    .reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String weekData = '';
                      switch (rodIndex) {
                        case 0:
                          weekData = 'Profit: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(rod.toY)}';
                          break;
                        case 1:
                          weekData = 'Penjualan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(rod.toY)}';
                          break;
                        case 2:
                          weekData = 'Pembelian: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(rod.toY)}';
                          break;
                      }
                      return BarTooltipItem(
                        'Week ${group.x + 1}\n$weekData',
                        TextStyle(color: Colors.black),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'W${value.toInt() + 1}',
                          style: TextStyle(
                            color: Color(0xFF080C67),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact(locale: 'id').format(value),
                          style: TextStyle(
                            color: Color(0xFF080C67),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: false,
                  drawVerticalLine: false,
                  horizontalInterval: 1000000,
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.entries.map((entry) {
                  final week = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: week - 1,
                    barRods: [
                      BarChartRodData(
                        toY: data['profit']!,
                        color: Color(0xFF2196F3),
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: data['penjualan']!,
                        color: Color(0xFF4CAF50),
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: data['pembelian']!,
                        color: Color(0xFFF44336),
                        width: 8,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLineChart(double height) {
    final List<FlSpot> profitSpots = [];
    final List<FlSpot> penjualanSpots = [];
    final List<FlSpot> pembelianSpots = [];

    weeklyData.forEach((week, data) {
      profitSpots.add(FlSpot(week.toDouble() - 1, data['profit']!));
      penjualanSpots.add(FlSpot(week.toDouble() - 1, data['penjualan']!));
      pembelianSpots.add(FlSpot(week.toDouble() - 1, data['pembelian']!));
    });

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profit Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF080C67),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String title = '';
                        Color color = Colors.black;
                        switch (spot.barIndex) {
                          case 0:
                            title = 'Profit';
                            color = Color(0xFF2196F3);
                            break;
                          case 1:
                            title = 'Penjualan';
                            color = Color(0xFF4CAF50);
                            break;
                          case 2:
                            title = 'Pembelian';
                            color = Color(0xFFF44336);
                            break;
                        }
                        return LineTooltipItem(
                          '$title\n${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(spot.y)}',
                          TextStyle(color: color),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'W${value.toInt() + 1}',
                          style: TextStyle(
                            color: Color(0xFF080C67),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact(locale: 'id').format(value),
                          style: TextStyle(
                            color: Color(0xFF080C67),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000000,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    color: Color(0xFF2196F3),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: penjualanSpots,
                    isCurved: true,
                    color: Color(0xFF4CAF50),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: pembelianSpots,
                    isCurved: true,
                    color: Color(0xFFF44336),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
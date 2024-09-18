import 'package:flutter/material.dart';


class PerAwal extends StatelessWidget {
  List<Tab> myTab = [
    Tab(
      text: 'P. Awal',
    ),
    Tab(
      text: 'Pembelian',
    ),
    Tab(
      text: 'P. Akhir',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: myTab.length,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w600,
            ),
            'Perusahaan Dagang',
          ),
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: TabBar(
                indicatorColor: Color(0xFFFFFFFF),
                indicatorPadding: EdgeInsets.all(5),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Color(0xFFFFFFFF),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                color: Color(0xFFFFFFFF),
                ),
                tabs: myTab,
              )),
          backgroundColor: Color(0xFF080C67),
        ),
        body: TabBarView(
          children: [
            Container(
              child: Column(children: [
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: Colors.black),
                    ),
                    leading: Icon(Icons.production_quantity_limits_sharp),
                    title: Text(
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 23),
                        'Pensil'),
                    subtitle: Text(
                        style: TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 12),
                        '100 pcs'),
                    trailing: Text(
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 18),
                        'Rp 1.000.000'),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 320,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF253475),
                    ),
                    onPressed: () {},
                    child: Text(
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      'Tambah',
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              child: Text('Penjualan'),
            ),
            Container(
              child: Text('P. Akhir'),
            )
          ],
        ),
      ),
    );
  }
}

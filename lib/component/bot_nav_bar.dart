import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hpp_project/theme.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: SizedBox(
            height: 24,
            width: 24,
            child: SvgPicture.asset('assets/icons/home-2.svg', color: secondary),
          ),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: SizedBox(
            height: 24,
            width: 24,
            child: SvgPicture.asset('assets/icons/note.svg', color: secondary),
          ),
          label: 'Laporan',
        ),
        BottomNavigationBarItem(
          icon: SizedBox(
            height: 24,
            width: 24,
            child: SvgPicture.asset('assets/icons/Profile.svg', color: secondary),
          ),
          label: 'Profile',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: secondary,
      onTap: onItemTapped,
    );
  }
}

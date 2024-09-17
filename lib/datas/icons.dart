import 'dart:ui';
import '../theme.dart';

List<HppIcon> HPPMenuBar = [
  HppIcon(icon: 'beranda', title: 'Beranda'),
  HppIcon(icon: 'laporan', title: 'Laporan'),
  HppIcon(icon: 'akun', title: 'Akun')
];

List<HppIcon> menuIcons = [
  HppIcon(icon: 'goride', title: 'GoRide', color: primary1),
  HppIcon(icon: 'gocar', title: 'GoCar', color: primary1),
  HppIcon(icon: 'gofood', title: 'GoFood', color: red),
  HppIcon(icon: 'gosend', title: 'GoSend', color: primary1),
  HppIcon(icon: 'gomart', title: 'GoMart', color: red),
  HppIcon(icon: 'gopulsa', title: 'GoPulsa', color: blue2),
  HppIcon(icon: 'goclub', title: 'GoClub', color: purple),
  HppIcon(icon: 'other', title: 'Lainnya', color: dark4),
];

class HppIcon {
  final String icon;
  final String title;
  final Color? color;

  HppIcon({required this.icon, required this.title, this.color});
}
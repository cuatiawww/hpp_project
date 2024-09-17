import 'package:flutter/material.dart';
import 'package:hpp_project/theme.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: RichText(
        text: TextSpan(
          text: "Hai, ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          children: [
            TextSpan(
              text: "Username",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            width: 30,
            height: 30,
            child: Image.asset(
              "../assets/icons/notification.png",
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
      backgroundColor: primary1,
      elevation: 0,
    );
  }
}

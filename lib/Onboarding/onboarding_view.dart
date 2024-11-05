import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hpp_project/onboarding/onboarding_items.dart';
import 'package:hpp_project/routes/routes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final controller = OnboardingItems();
  final pageController = PageController();

  bool isLastPage = false;
  int currentIndex = 0;

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: PageView.builder(
          itemCount: controller.items.length,
          onPageChanged: (index) => setState(() => isLastPage = controller.items.length - 1 == index),
          controller: pageController,
          itemBuilder: (context, index) {
            return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                controller.items[index].image,
                width: 330,
              ),
              SizedBox(height: 20),
              Text(
                controller.items[index].title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  controller.items[index].description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 50),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SmoothPageIndicator(
                      controller: pageController,
                      count: controller.items.length,
                      onDotClicked: (page) => pageController.animateToPage(page, duration: Duration(milliseconds: 600), curve: Curves.easeInOut),
                      effect: ExpandingDotsEffect(
                        dotHeight: 13,
                        dotWidth: 13,
                        activeDotColor: Color(0xff080C67),
                        dotColor: Color(0xffC4C4C4),
                      ),
                    ),
                  ]
                ),
              ),
              SizedBox(height: 50),
              isLastPage? getStarted() : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    width: 163,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff080C67),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        pageController.jumpToPage(controller.items.length - 1);
                      },
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Color(0xffffffff),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 163,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffffffff),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Color(0xffF29100)),
                        ),
                      ),
                      onPressed: () {
                        pageController.nextPage(duration: Duration(milliseconds: 700), curve: Curves.easeIn);
                      },
                      child: Text(
                        "Next",
                        style: TextStyle(
                          color: Color(0xffF29100),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
          }
        ),
      ),
    );
  }

  Widget getStarted() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: 163,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff080C67),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Get.toNamed(Routes.login),
            child: Text(
              "Masuk",
              style: TextStyle(
                color: Color(0xffffffff),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        Container(
          width: 163,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xffffffff),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: Color(0xffF29100)),
              ),
            ),
            onPressed: () => Get.toNamed(Routes.regist),
            child: Text(
              "Daftar",
              style: TextStyle(
                color: Color(0xffF29100),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
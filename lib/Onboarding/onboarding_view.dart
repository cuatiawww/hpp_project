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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Content
                  Positioned.fill(
                    bottom: 120, // Memberikan ruang untuk button di bawah
                    child: PageView.builder(
                      itemCount: controller.items.length,
                      onPageChanged: (index) {
                        setState(() {
                          isLastPage = index == controller.items.length - 1;
                        });
                      },
                      controller: pageController,
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              const SizedBox(height: 40),
                              Image.asset(
                                controller.items[index].image,
                                width: 330,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                controller.items[index].title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                controller.items[index].description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              SmoothPageIndicator(
                                controller: pageController,
                                count: controller.items.length,
                                effect: const ExpandingDotsEffect(
                                  dotHeight: 13,
                                  dotWidth: 13,
                                  activeDotColor: Color(0xff080C67),
                                  dotColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                  // Fixed Bottom Buttons
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 20,
                    ),
                    child: isLastPage
                      ? getStarted()
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildButton(
                            "Skip",
                            const Color(0xff080C67),
                            Colors.white,
                            null,
                            () => pageController.jumpToPage(
                              controller.items.length - 1,
                            ),
                          ),
                          _buildButton(
                            "Next",
                            Colors.white,
                            const Color(0xffF29100),
                            const Color(0xffF29100),
                            () => pageController.nextPage(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color backgroundColor,
    Color textColor,
    Color? borderColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 163,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget getStarted() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(
            "Masuk",
            const Color(0xff080C67),
            Colors.white,
            null,
            () => Get.toNamed(Routes.login),
          ),
          _buildButton(
            "Daftar",
            Colors.white,
            const Color(0xffF29100),
            const Color(0xffF29100),
            () => Get.toNamed(Routes.regist),
          ),
        ],
      ),
    );
  }
}

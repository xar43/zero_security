import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/constants/app_assets.dart';
import 'package:toggle_timer/config/local/local_storage_services.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';
import 'package:toggle_timer/core/common_widgets/custom_image_widget.dart';
import 'package:toggle_timer/features/auth/screens/login_screen.dart';
import 'package:toggle_timer/features/home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoOpacityAnimation;

  // Animations for positioned images
  late final Animation<double> _topRightImageAnimation;
  late final Animation<double> _leftCircleAnimation;
  late final Animation<double> _bottomCircleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 2 seconds duration
    _controller = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    // Create staggered animations for positioned images
    _topRightImageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _leftCircleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
      ),
    );

    _bottomCircleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo animations (starts after positioned images)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
      ),
    );

    // Start the animation
    _controller.forward().then(
      (_) => _controller.reverse().then(
        (_) => Get.offAll(() => LocalStorageServices.getToken() != null ? HomeScreen() : LoginScreen()),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        children: [
          // Logo and text (appears last)
          Center(
            child: Opacity(
              opacity: _logoOpacityAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: CustomImageWidget(imageUrl: AppAssets.icon),
                  ),
                  Transform.translate(
                    offset: Offset(0, -25),
                    child: Text("Toggle Timer", style: AppTypography.style24SemiBold),
                  ),
                ],
              ),
            ),
          ),

          // Top right image (appears first)
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: _topRightImageAnimation.value,
              child: Transform.translate(
                offset: Offset(
                  50 * (1 - _topRightImageAnimation.value), // Slide in from right
                  0,
                ),
                child: CustomImageWidget(imageUrl: AppAssets.halfFilledCircle),
              ),
            ),
          ),

          // Left circle (appears second)
          Positioned(
            top: context.height * .55,
            child: Opacity(
              opacity: _leftCircleAnimation.value,
              child: Transform.translate(
                offset: Offset(
                  -50 * (1 - _leftCircleAnimation.value), // Slide in from left
                  0,
                ),
                child: CustomImageWidget(imageUrl: AppAssets.splashLeftCircle),
              ),
            ),
          ),

          // Bottom circle (appears third)
          Positioned(
            bottom: 0,
            right: 4,
            child: Opacity(
              opacity: _bottomCircleAnimation.value,
              child: Transform.translate(
                offset: Offset(
                  0,
                  50 * (1 - _bottomCircleAnimation.value), // Slide up from bottom
                ),
                child: CustomImageWidget(imageUrl: AppAssets.splashbottomcircle),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

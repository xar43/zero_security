import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toggle_timer/config/constants/app_assets.dart';
import 'package:toggle_timer/config/typography/app_typography.dart';
import 'package:toggle_timer/core/common_widgets/custom_image_widget.dart';
import 'package:toggle_timer/core/common_widgets/custom_text_field.dart';
import 'package:toggle_timer/core/utils/app_prompts.dart';
import 'package:toggle_timer/features/auth/controller/auth_controller.dart';
import 'package:toggle_timer/features/auth/models/login_model.dart';
import 'package:toggle_timer/features/home/screens/home_screen.dart';

import '../../../config/colors/app_colors.dart';
import '../../../core/common_widgets/custom_app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoOpacityAnimation;

  // Animations for positioned images
  late final Animation<double> _topRightImageAnimation;
  late final Animation<double> _leftCircleAnimation;
  late final Animation<double> _bottomCircleAnimation;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final _authController = Get.put(AuthController());

  final _formKey = GlobalKey<FormState>();

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

    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      // Real login using valid credentials
      final success = await _authController.login(
        LoginRequestModel(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
      
      if (success) {
        AppPrompts.showSuccess(message: "Logged in successfully");
        Get.offAll(() => const HomeScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        children: [
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
            top: context.height * .25,
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
          // Logo and text (appears last)
          Center(
            child: Opacity(
              opacity: _logoOpacityAnimation.value,
              child: Transform.scale(
                scale: _logoScaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.kAppBlack,
                    border: Border.all(color: AppColors.kAppGrey.shade800),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(scale: .7, child: CustomImageWidget(imageUrl: AppAssets.icon)),
                        CustomTextField(
                          headingLabelText: "Email",
                          hintText: "e.g test@example.com",
                          headingStyle: AppTypography.style20Regular,
                          controller: _emailController,
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          headingStyle: AppTypography.style20Regular,
                          headingLabelText: "Password",
                          controller: _passwordController,
                          isPassword: true,
                        ),
                        SizedBox(height: 30),
                        Obx(
                          () =>
                              CustomAppButton(text: "LOGIN", onPressed: _onLogin, isLoading: _authController.isLoading),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

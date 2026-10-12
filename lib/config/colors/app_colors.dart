import 'package:flutter/material.dart';

import '../../main.dart';

abstract class AppColors {
  static BuildContext get _context => navigatorKey.currentContext!;

  static ColorScheme get _colorScheme => Theme.of(_context).colorScheme;

  static Color get kAppPrimary => _colorScheme.primary;
  static Color get kAppSecondary => _colorScheme.secondary;
  static Color get kAppBackground => _colorScheme.surface;
  static Color get kAppOnBackground => _colorScheme.onSurface;
  static Color get kAppError => _colorScheme.error;
  static Color get kAppOnError => _colorScheme.onError;
  static Color get kAppOnPrimary => _colorScheme.onPrimary;
  static Color get kAppCardColor => _colorScheme.surfaceContainer;
  static Color get kAppScaffold => Theme.of(_context).scaffoldBackgroundColor;

  static const Color kAppWhite = Colors.white;
  static const Color kAppBlack = Colors.black;
  static const MaterialColor kAppGrey = Colors.grey;

  static const Color kAppDisabled = Color(0xFFBDBDBD);

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color.fromRGBO(146, 254, 159, 1), Color.fromRGBO(0, 201, 255, 1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const greenColor = Color(0xFF47D44C);
  static const greenBackgroundColor = Color(0x4051BA8B); // 25% opacity (0x40 = 64 decimal)
  static const brownColor = Color(0xFF815114);
}

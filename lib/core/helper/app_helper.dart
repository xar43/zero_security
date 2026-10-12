import 'package:flutter/material.dart';

class AppHelper {
  static Widget buildDrawerButton(GlobalKey<ScaffoldState> scaffoldKey) => IconButton(
    onPressed: () => scaffoldKey.currentState?.openDrawer(),
    icon: Icon(Icons.menu),
    style: IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: .6),
      foregroundColor: Colors.white,
      iconSize: 30,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

import 'package:flutter/material.dart';

/// Bottom padding for modal bottom sheets that accounts for the
/// floating nav bar (~76px) when the keyboard is not open.
double sheetBottomPadding(BuildContext context) {
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
  final safeBottom = MediaQuery.of(context).viewPadding.bottom;
  // Keyboard open: nav is covered, just add small padding above keyboard.
  // Keyboard closed: clear the floating nav bar (64h + 12 margin + 16 gap).
  return keyboardHeight > 0 ? keyboardHeight + 16 : safeBottom + 96;
}

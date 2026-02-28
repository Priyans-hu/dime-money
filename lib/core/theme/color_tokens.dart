import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const seedColor = Color(0xFF6750A4);

  // Category palette for picker
  static const categoryPalette = [
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFF9CCC65), // Light Green
    Color(0xFFFFCA28), // Amber
    Color(0xFFFFA726), // Orange
    Color(0xFFFF7043), // Deep Orange
    Color(0xFF8D6E63), // Brown
    Color(0xFF78909C), // Blue Grey
  ];

  // Budget progress colors
  static const budgetSafe = Color(0xFF66BB6A);
  static const budgetWarning = Color(0xFFFFCA28);
  static const budgetDanger = Color(0xFFEF5350);
}

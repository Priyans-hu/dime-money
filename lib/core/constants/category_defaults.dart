import 'package:flutter/material.dart';

class DefaultCategory {
  final String name;
  final IconData icon;
  final Color color;

  const DefaultCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const defaultCategories = [
  DefaultCategory(
    name: 'Food & Drinks',
    icon: Icons.restaurant,
    color: Color(0xFFEF5350),
  ),
  DefaultCategory(
    name: 'Transport',
    icon: Icons.directions_car,
    color: Color(0xFF42A5F5),
  ),
  DefaultCategory(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Color(0xFFAB47BC),
  ),
  DefaultCategory(
    name: 'Entertainment',
    icon: Icons.movie,
    color: Color(0xFFFF7043),
  ),
  DefaultCategory(
    name: 'Bills & Utilities',
    icon: Icons.receipt_long,
    color: Color(0xFF66BB6A),
  ),
  DefaultCategory(
    name: 'Health',
    icon: Icons.favorite,
    color: Color(0xFFEC407A),
  ),
  DefaultCategory(
    name: 'Education',
    icon: Icons.school,
    color: Color(0xFF5C6BC0),
  ),
  DefaultCategory(
    name: 'Other',
    icon: Icons.more_horiz,
    color: Color(0xFF78909C),
  ),
];

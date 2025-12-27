import 'package:flutter/material.dart';

/// App shadow styles - soft iOS-like shadows
class AppShadows {
  AppShadows._();

  // No shadow
  static const List<BoxShadow> none = [];

  // Extra small - subtle elevation
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  // Small - cards, buttons
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  // Medium - floating elements
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  // Large - modals, dropdowns
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  // Extra large - prominent elements
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  // Card shadow - default for cards (more visible)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x12000000), // Increased opacity for better visibility
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Card shadow elevated - for prominent cards
  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // Button shadow
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x1A2563EB),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Bottom navigation shadow
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, -2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Floating action button shadow
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x262563EB),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Inner shadow (for inputs)
  static List<BoxShadow> inner = [
    BoxShadow(
      color: const Color(0x0A000000),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
}


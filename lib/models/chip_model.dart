import 'package:flutter/material.dart';

/// Modello rappresentante una fiche da casino
class ChipModel {
  final int value;
  final Color color;
  final Color borderColor;
  final String label;

  const ChipModel({
    required this.value,
    required this.color,
    required this.borderColor,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

/// Fiches disponibili nel gioco
class GameChips {
  static const List<ChipModel> values = [
    ChipModel(
      value: 1,
      color: Color(0xFFFFFFFF),
      borderColor: Color(0xFFCCCCCC),
      label: '1',
    ),
    ChipModel(
      value: 5,
      color: Color(0xFFFF0055),
      borderColor: Color(0xFFCC0044),
      label: '5',
    ),
    ChipModel(
      value: 10,
      color: Color(0xFF0088FF),
      borderColor: Color(0xFF0066CC),
      label: '10',
    ),
    ChipModel(
      value: 25,
      color: Color(0xFF00FF9D),
      borderColor: Color(0xFF00CC7D),
      label: '25',
    ),
    ChipModel(
      value: 100,
      color: Color(0xFF1a1a1a),
      borderColor: Color(0xFF444444),
      label: '100',
    ),
    ChipModel(
      value: 500,
      color: Color(0xFF8B00FF),
      borderColor: Color(0xFF6600CC),
      label: '500',
    ),
  ];

  static ChipModel? getByValue(int value) {
    try {
      return values.firstWhere((c) => c.value == value);
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';

/// Helper class for backward compatibility with hexcolor package
class HexColor extends Color {
  HexColor(String hex) : super(_parseHex(hex));
  
  static int _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return int.parse(buffer.toString(), radix: 16);
  }
}


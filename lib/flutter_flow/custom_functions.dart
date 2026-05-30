import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';

String? jsonToString(dynamic statusResponseJSON) {
  if (statusResponseJSON is! Map<String, dynamic>) {
    return null;
  }

  if (statusResponseJSON is! Map<String, dynamic>) {
    return null;
  }

  // Function to recursively process JSON object and return plain text
  String processJson(Map<String, dynamic> json) {
    List<String> result = [];
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result.add("$key:${processJson(value)}");
      } else if (value is List) {
        result.add("$key:${value.map((v) => v.toString()).join(',')}");
      } else {
        result.add("$key:$value");
      }
    });
    return result.join(',');
  }

  // Convert JSON object to plain text without braces
  String plainText = processJson(statusResponseJSON);

  // Remove any remaining braces, extra commas, and spaces
  plainText = plainText
      .replaceAll(RegExp(r'[{}]'), '')
      .replaceAll(',,', ',')
      .replaceAll('"', '')
      .replaceAll("'", '');

  return plainText;
}

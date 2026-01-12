import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLayout {
  // --- Dimensions ---
  static const double bookBorderRadius = 24.0;
  static const double spineWidth = 60.0;
  static const double pageBorderRadius = 16.0;

  // Book Cover
  static const double coverPadding = 32.0;
  static const double coverIconSize = 100.0;

  // Index/TOC
  static const double indexHeaderHeight = 80.0;
  static const double indexItemHeight = 48.0; // Approx height of a list item
  static const int defaultItemsPerPage = 13;

  // --- Styles ---
  static TextStyle get titleStyle =>
      GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold);

  static TextStyle get bodyStyle => GoogleFonts.lato();
}

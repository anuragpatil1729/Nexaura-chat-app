
import 'package:flutter/material.dart';

// Color Palette
const Color cyberpunkBlack = Color(0xFF0A0A0A);
const Color neonMagenta = Color(0xFFFF00FF);
const Color neonCyan = Color(0xFF00FFFF);
const Color darkGrey = Color(0xFF1E1E1E);
const Color lightGrey = Color(0xFF8A8A8A);

final ThemeData cyberpunkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: cyberpunkBlack,
  scaffoldBackgroundColor: cyberpunkBlack,
  fontFamily: 'Cyberpunk', // Make sure to add a cyberpunk font to your project

  colorScheme: const ColorScheme.dark(
    primary: neonMagenta,
    secondary: neonCyan,
    surface: darkGrey,
    background: cyberpunkBlack,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    onBackground: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: cyberpunkBlack,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Cyberpunk',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: neonCyan,
    ),
    iconTheme: IconThemeData(color: neonCyan),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: neonMagenta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: neonMagenta, width: 2),
      ),
      textStyle: const TextStyle(fontFamily: 'Cyberpunk', fontWeight: FontWeight.bold),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: darkGrey,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(0)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(0)),
      borderSide: BorderSide(color: neonMagenta, width: 2),
    ),
    labelStyle: TextStyle(color: lightGrey),
  ),

  listTileTheme: const ListTileThemeData(
    tileColor: Colors.transparent,
    textColor: Colors.white,
    subtitleTextStyle: TextStyle(color: lightGrey),
  ),

  iconTheme: const IconThemeData(
    color: neonCyan,
  ),
);

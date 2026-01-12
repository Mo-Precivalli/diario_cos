import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:diario_mestre/providers/notebook_provider.dart';
import 'package:diario_mestre/features/home/screens/home_screen.dart';
import 'package:diario_mestre/core/theme/colors.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  // Inicializar SQLite FFI para desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const DiarioDoMestreApp());
}

class DiarioDoMestreApp extends StatelessWidget {
  const DiarioDoMestreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotebookProvider(),
      child: MaterialApp(
        title: 'Diário do Mestre - D&D 2024',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme.copyWith(
          textTheme: GoogleFonts.latoTextTheme(AppTheme.theme.textTheme),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        home: const HomeScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

class PsxMpqConverterApp extends StatefulWidget {
  const PsxMpqConverterApp({super.key});

  @override
  State<PsxMpqConverterApp> createState() => _PsxMpqConverterAppState();
}

class _PsxMpqConverterAppState extends State<PsxMpqConverterApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSXVoice2MPQ',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        currentLocale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}

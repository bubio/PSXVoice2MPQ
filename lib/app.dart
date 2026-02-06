import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'l10n/app_localizations.dart';
import 'services/mpq_builder_service.dart';
import 'services/settings_service.dart';
import 'views/home_view.dart';
import 'widgets/settings_dialog.dart';

class PsxMpqConverterApp extends StatefulWidget {
  const PsxMpqConverterApp({super.key});

  @override
  State<PsxMpqConverterApp> createState() => _PsxMpqConverterAppState();
}

class _PsxMpqConverterAppState extends State<PsxMpqConverterApp> with WidgetsBindingObserver {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedLocale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Ensure all processes are killed when the app is closed
      getIt<MpqBuilderService>().cancel();
    }
  }

  Future<void> _loadSavedLocale() async {
    final settingsService = getIt<SettingsService>();
    final savedKey = await settingsService.getLocale();
    if (savedKey != null) {
      setState(() {
        _locale = SettingsDialog.parseLocaleKey(savedKey);
      });
    }
  }

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    final key = SettingsDialog.getLocaleKey(locale);
    getIt<SettingsService>().setLocale(key == 'system' ? null : key);
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
          seedColor: const Color(0xFF7D724C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeView(
        currentLocale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}

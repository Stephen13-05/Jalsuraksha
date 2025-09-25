import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  static final LocaleController instance = LocaleController._internal();
  LocaleController._internal();

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

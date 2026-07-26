import 'package:flutter/material.dart';
import '../shared/localization.dart';

class LanguageProvider extends ChangeNotifier {
  bool get isEnglish => AppLocale.isEnglish;

  void setEnglish() {
    AppLocale.setEnglish();
    notifyListeners();
  }

  void setIndonesian() {
    AppLocale.setIndonesian();
    notifyListeners();
  }

  void toggle() {
    if (isEnglish) {
      setIndonesian();
    } else {
      setEnglish();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeNotifier = ValueNotifier<String>('zh');

const _kLocale = 'locale_v1';

Future<void> initLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kLocale);
  if (saved != null) localeNotifier.value = saved;
  localeNotifier.addListener(() {
    prefs.setString(_kLocale, localeNotifier.value);
  });
}

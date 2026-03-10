import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

import 'i18n/strings_en.dart';
import 'i18n/strings_zh.dart';
import 'i18n/strings_fr.dart';
import 'i18n/strings_de.dart';
import 'i18n/strings_it.dart';
import 'i18n/strings_ja.dart';
import 'i18n/strings_ko.dart';
import 'i18n/strings_es.dart';

class AppStrings {
  static String currentLanguageCode = 'en';

  static final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    // CJK + EFIGS in alphabetical order by English name
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
  ];

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': stringsEn,
    'zh': stringsZh,
    'fr': stringsFr,
    'de': stringsDe,
    'it': stringsIt,
    'ja': stringsJa,
    'ko': stringsKo,
    'es': stringsEs,
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguageCode = prefs.getString('app_lang') ?? 'en';
  }

  static Future<void> setLanguage(String langCode) async {
    currentLanguageCode = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
  }

  static String get helpOverlayText => _get('helpOverlayText');
  static String get helpPara1 => _get('helpPara1');
  static String get helpPara2 => _get('helpPara2');
  static String get helpBullet1 => _get('helpBullet1');
  static String get helpBullet2 => _get('helpBullet2');
  static String get helpBullet3 => _get('helpBullet3');

  static String get difficulty => _get('difficulty');
  static String get crazyToTry => _get('crazyToTry');
  static String get hint => _get('hint');
  static String get giveUp => _get('giveUp');
  static String get showTimer => _get('showTimer');
  static String get flatStyle => _get('flatStyle');
  static String get displayMode => _get('displayMode');
  static String get language => _get('language');
  static String get help => _get('help');
  static String get resetPadlock => _get('resetPadlock');
  static String get showSplashScreen => _get('showSplashScreen');
  static String get puzzleSolvedGreatJob => _get('puzzleSolvedGreatJob');
  static String get puzzleSolved => _get('puzzleSolved');
  static String get doNotShowAgain => _get('doNotShowAgain');
  static String get startGame => _get('startGame');
  static String get thankYouForCoffee => _get('thankYouForCoffee');
  static String get purchaseFailed => _get('purchaseFailed');
  static String get buyMeACoffee => _get('buyMeACoffee');
  static String get confirmTip => _get('confirmTip');

  static String get progress => _get('progress');
  static String get moves => _get('moves');
  static String get hints => _get('hints');
  static String get gameStateSaved => _get('gameStateSaved');
  static String get exitPuzzle => _get('exitPuzzle');

  static String _get(String key) {
    return _localizedStrings[currentLanguageCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  static String getDisplayMode(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.colours:
        return _get('colorMode');
      case DisplayMode.patterns:
        return _get('patternsMode');
      case DisplayMode.numbers:
        return _get('numbersMode');
    }
  }
}

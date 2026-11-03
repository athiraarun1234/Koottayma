// import 'package:shared_preferences/shared_preferences.dart';

// class LanguagePreferences {
//   static const String _languageIdKey = 'selected_language_id';
//   static const String _languageNameKey = 'selected_language_name';

//   static Future<void> saveSelectedLanguage(int languageId, String languageName) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_languageIdKey, languageId);
//     await prefs.setString(_languageNameKey, languageName);
//   }

//   static Future<int?> getSelectedLanguageId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_languageIdKey);
//   }

//   static Future<String?> getSelectedLanguageName() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_languageNameKey);
//   }

//   static Future<bool> isLanguageSelected() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey(_languageIdKey);
//   }

//   static Future<void> clearLanguageSelection() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_languageIdKey);
//     await prefs.remove(_languageNameKey);
//   }
// }
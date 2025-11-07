import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Initialize storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== CHAT HISTORY ==========
  
  Future<void> saveChatHistory(List<Map<String, String>> history) async {
    final jsonString = jsonEncode(history);
    await _prefs?.setString('chat_history', jsonString);
  }

  List<Map<String, String>> getChatHistory() {
    final jsonString = _prefs?.getString('chat_history');
    if (jsonString == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  Future<void> clearChatHistory() async {
    await _prefs?.remove('chat_history');
  }

  // ========== SETTINGS ==========
  
  Future<void> saveFloatingButtonEnabled(bool enabled) async {
    await _prefs?.setBool('floating_button_enabled', enabled);
  }

  bool getFloatingButtonEnabled() {
    return _prefs?.getBool('floating_button_enabled') ?? true;
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs?.setString('theme_mode', mode);
  }

  String getThemeMode() {
    return _prefs?.getString('theme_mode') ?? 'light';
  }

  Future<void> saveDefaultLanguage(String language) async {
    await _prefs?.setString('default_language', language);
  }

  String getDefaultLanguage() {
    return _prefs?.getString('default_language') ?? 'English';
  }

  // ========== PERMISSIONS ==========
  
  Future<void> savePermissionStatus(String permission, bool granted) async {
    await _prefs?.setBool('permission_$permission', granted);
  }

  bool getPermissionStatus(String permission) {
    return _prefs?.getBool('permission_$permission') ?? false;
  }

  // ========== FIRST TIME USER ==========
  
  Future<void> setFirstTimeLaunch(bool isFirstTime) async {
    await _prefs?.setBool('first_time_launch', isFirstTime);
  }

  bool isFirstTimeLaunch() {
    return _prefs?.getBool('first_time_launch') ?? true;
  }

  // ========== CLEAR ALL DATA ==========
  
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

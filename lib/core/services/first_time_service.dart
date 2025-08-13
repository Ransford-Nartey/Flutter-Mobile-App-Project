import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeService {
  static const String _firstTimeKey = 'isFirstTime';
  
  /// Check if this is the first time the user is visiting the app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }
  
  /// Mark that the user has completed onboarding (not first time anymore)
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
  }
  
  /// Reset to first time (useful for testing)
  static Future<void> resetToFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, true);
  }
}

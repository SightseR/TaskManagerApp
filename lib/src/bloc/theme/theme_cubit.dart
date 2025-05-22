// lib/src/bloc/theme/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeData themeData;
  final bool isDark;
  ThemeState({required this.themeData, required this.isDark});
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _prefKey = 'isDarkMode';

  ThemeCubit() : super(
    ThemeState(themeData: ThemeData.light(), isDark: false)
  ) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    emit(ThemeState(
      themeData: isDark ? ThemeData.dark() : ThemeData.light(),
      isDark: isDark,
    ));
  }

  Future<void> toggleTheme() async {
    final newIsDark = !state.isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, newIsDark);
    emit(ThemeState(
      themeData: newIsDark ? ThemeData.dark() : ThemeData.light(),
      isDark: newIsDark,
    ));
  }
}

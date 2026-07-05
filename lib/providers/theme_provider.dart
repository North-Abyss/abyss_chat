import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/services/shared_prefs_helper.dart';

class ThemeState {
  final ThemeMode mode;
  final String themeName;
  final Color? customColor;
  const ThemeState(this.mode, this.themeName, {this.customColor});
}

final predefinedThemes = <String, Color>{
  "Abyss Purple": const Color(0xFF6750A4),
  "Ocean Blue": Colors.blue,
  "Forest Green": Colors.green,
  "Sunset Orange": Colors.orange,
  "Cherry Red": Colors.red,
  "Teal": Colors.teal,
  "Pink": Colors.pink,
  "Amber": Colors.amber,
  "Indigo": Colors.indigo,
  "Slate": Colors.blueGrey,
  "Cyan": Colors.cyan,
  "Earth": Colors.brown,
};

class ThemeNotifier extends AsyncNotifier<ThemeState> {
  @override
  Future<ThemeState> build() async {
    final prefs = await SharedPrefsHelper.instance;
    final modeIndex = prefs.getInt('themeMode') ?? 0;
    final themeName = prefs.getString('themeName') ?? "Teal";
    final customHex = prefs.getInt('customColorValue');
    final customColor = customHex != null ? Color(customHex) : null;
    return ThemeState(ThemeMode.values[modeIndex], themeName, customColor: customColor);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setInt('themeMode', mode.index);
    if (state.hasValue) {
      state = AsyncData(ThemeState(mode, state.value!.themeName, customColor: state.value!.customColor));
    }
  }

  Future<void> setTheme(String themeName) async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setString('themeName', themeName);
    if (state.hasValue) {
      state = AsyncData(ThemeState(state.value!.mode, themeName, customColor: state.value!.customColor));
    }
  }

  Future<void> setCustomColor(Color color) async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setInt('customColorValue', color.toARGB32());
    await prefs.setString('themeName', 'Custom');
    if (state.hasValue) {
      state = AsyncData(ThemeState(state.value!.mode, 'Custom', customColor: color));
    }
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

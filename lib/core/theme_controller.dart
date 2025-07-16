// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeController with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  FlexScheme? _currentScheme;

  ThemeMode get themeMode => _themeMode;
  FlexScheme? get currentScheme => _currentScheme;
  static final List<FlexScheme> availableThemes = [
    FlexScheme.material,
    FlexScheme.materialHc,
    FlexScheme.blue,
    FlexScheme.indigo,
    FlexScheme.hippieBlue,
    FlexScheme.aquaBlue,
    FlexScheme.brandBlue,
    FlexScheme.deepBlue,
    FlexScheme.sakura,
    FlexScheme.mandyRed,
    FlexScheme.red,
    FlexScheme.redWine,
    FlexScheme.purpleBrown,
    FlexScheme.green,
    FlexScheme.money,
    FlexScheme.jungle,
    FlexScheme.greyLaw,
    FlexScheme.wasabi,
    FlexScheme.gold,
    FlexScheme.mango,
    FlexScheme.amber,
    FlexScheme.vesuviusBurn,
    FlexScheme.deepPurple,
    FlexScheme.ebonyClay,
    FlexScheme.barossa,
    FlexScheme.shark,
    FlexScheme.bigStone,
    FlexScheme.damask,
    FlexScheme.bahamaBlue,
    FlexScheme.sanJuanBlue,
    FlexScheme.espresso,
    FlexScheme.outerSpace,
    FlexScheme.blueWhale,
    FlexScheme.blumineBlue,
    FlexScheme.purpleM3,
    FlexScheme.blueM3,
    FlexScheme.indigoM3,
    FlexScheme.pinkM3,
    FlexScheme.redM3,
    FlexScheme.tealM3,
    FlexScheme.greenM3,
    FlexScheme.yellowM3,
    FlexScheme.orangeM3,
  ];

  Future<void> showThemeDialog(BuildContext context) async {
    final currentScheme = await getCurrentScheme();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择主题'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableThemes.length,
              itemBuilder: (BuildContext context, int index) {
                final scheme = availableThemes[index];
                return ListTile(
                  title: Text(scheme.name),
                  trailing:
                      currentScheme == scheme ? const Icon(Icons.check) : null,
                  onTap: () {
                    saveCurrentScheme(scheme);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  static const String _currentSchemeKey = 'current_scheme';

  Future<FlexScheme?> getCurrentScheme() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeIndex = prefs.getInt(_currentSchemeKey);
    return schemeIndex != null ? FlexScheme.values[schemeIndex] : null;
  }

  Future<void> saveCurrentScheme(FlexScheme scheme) async {
    _currentScheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentSchemeKey, scheme.index);
    notifyListeners();
  }

  static const String _themeModeKey = 'theme_mode';

  Future<ThemeMode?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    return themeIndex != null ? ThemeMode.values[themeIndex] : null;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, themeMode.index);
  }

  Future<void> initializeTheme() async {
    _themeMode = await getThemeMode() ?? ThemeMode.light;
    _currentScheme = await getCurrentScheme();
    notifyListeners();
  }

  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    await saveThemeMode(_themeMode);
    notifyListeners();
  }

  static bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    await saveThemeMode(_themeMode);
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    await saveThemeMode(_themeMode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await saveThemeMode(_themeMode);
    notifyListeners();
  }
}

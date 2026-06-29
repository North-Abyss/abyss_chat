import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:abyss_chat/screens/login_screen.dart';
import 'package:abyss_chat/providers/theme_provider.dart';
import 'package:abyss_chat/providers/call_provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AbyssApp(),
    ),
  );
}

class AbyssApp extends ConsumerWidget {
  const AbyssApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeStateAsync = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return themeStateAsync.when(
          data: (themeState) {
            Color? seedColor;
            if (themeState.themeName == 'Custom' && themeState.customColor != null) {
              seedColor = themeState.customColor!;
            } else if (themeState.themeName != 'Default') {
              seedColor = predefinedThemes[themeState.themeName];
            }

            return MaterialApp(
              title: 'Abyss Chat',
              debugShowCheckedModeBanner: false,
              navigatorKey: globalNavigatorKey,
              themeMode: themeState.mode,
              theme: _buildTheme(seedColor, Brightness.light, lightDynamic),
              darkTheme: _buildTheme(seedColor, Brightness.dark, darkDynamic),
              home: const LoginScreen(),
            );
          },
          loading: () => const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, stack) => MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text('Error loading theme: $err')),
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Color? seedColor, Brightness brightness, ColorScheme? dynamicScheme) {
    ColorScheme colorScheme;
    
    if (seedColor == null && dynamicScheme != null) {
      // Use device dynamic color if no custom/predefined seed is set
      colorScheme = dynamicScheme;
    } else {
      // Fallback to custom/predefined seed or default teal
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor ?? Colors.teal,
        brightness: brightness,
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        selectedTileColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.onSecondaryContainer,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      textTheme: GoogleFonts.comfortaaTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
    );
  }
}

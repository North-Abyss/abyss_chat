import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:abyss_chat/screens/login_screen.dart';
import 'package:abyss_chat/providers/theme_provider.dart';
import 'package:abyss_chat/services/notification_service.dart';
import 'package:abyss_chat/providers/call_provider.dart';

void main() {
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

    return themeStateAsync.when(
      data: (themeState) {
        Color seedColor;
        if (themeState.themeName == 'Custom' && themeState.customColor != null) {
          seedColor = themeState.customColor!;
        } else {
          seedColor = predefinedThemes[themeState.themeName] ?? Colors.teal;
        }

        return MaterialApp(
          title: 'Abyss Chat',
          debugShowCheckedModeBanner: false,
          navigatorKey: globalNavigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          themeMode: themeState.mode,
          theme: _buildTheme(seedColor, Brightness.light),
          darkTheme: _buildTheme(seedColor, Brightness.dark),
          home: const LoginScreen(),
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error loading theme: $err')),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_expense_tracker/ui/blocs/transaction/transaction_cubit.dart';

import 'data/services/transaction_service.dart';
import 'ui/blocs/auth/auth_cubit.dart';
import 'ui/screens/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'ui/blocs/theme/theme_cubit.dart';

abstract final class AppColors {
  static const Color navy = Color(0xFF101D2C);
  static const Color navyLight = Color(0xFF1B3042);
  static const Color emerald = Color(0xFF0F766E);
  static const Color emeraldDark = Color(0xFF115E59);
  static const Color mint = Color(0xFFB9E4D0);
  static const Color mintLight = Color(0xFFE3F3EB);
  static const Color background = Color(0xFFF3F5F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF182A35);
  static const Color textSecondary = Color(0xFF697A80);
  static const Color border = Color(0xFFE1E8E3);
  static const Color income = Color(0xFF168568);
  static const Color expense = Color(0xFFC45B58);
  static const Color error = Color(0xFFB42318);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<TransactionCubit>(
          create: (_) => TransactionCubit(TransactionService()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Personal Expense Tracker',
            theme: _buildTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeMode,
            themeAnimationDuration: Duration.zero,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.border,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      secondary: AppColors.mint,
      onSecondary: AppColors.navy,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: Color(0xFFE8EEE9),
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: Color(0xFFD3DED6),
      shadow: Color(0x1A101D2C),
      scrim: Color(0x80000000),
      inverseSurface: AppColors.navy,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.mint,
      tertiary: AppColors.navyLight,
      onTertiary: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIconColor: AppColors.emerald,
      suffixIconColor: AppColors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.emerald,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.emeraldDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.mintLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selected = states.contains(WidgetState.selected);

        return IconThemeData(
          color: selected ? AppColors.emeraldDark : AppColors.textSecondary,
          size: 23,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final selected = states.contains(WidgetState.selected);

        return TextStyle(
          color: selected ? AppColors.emeraldDark : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.emerald,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.emerald
            : Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),

    textTheme: const TextTheme(
      displaySmall: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        inherit: true,
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        inherit: true,
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        inherit: true,
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        inherit: true,
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const darkBackground = Color(0xFF101D2C);
  const darkSurface = Color(0xFF1B3042);
  const darkText = Color(0xFFF3F5F2);
  const darkMuted = Color(0xFFB0BEC5);
  const darkBorder = Color(0xFF344957);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkBackground,
    dividerColor: darkBorder,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.mint,
      onPrimary: AppColors.navy,
      secondary: AppColors.emerald,
      onSecondary: Colors.white,
      error: Color(0xFFFF8A80),
      onError: AppColors.navy,
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: Color(0xFF293D4D),
      onSurfaceVariant: darkMuted,
      outline: darkBorder,
      outlineVariant: Color(0xFF405563),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: darkText,
      onInverseSurface: AppColors.navy,
      inversePrimary: AppColors.emerald,
      tertiary: AppColors.mint,
      onTertiary: AppColors.navy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      hintStyle: const TextStyle(color: darkMuted),
      labelStyle: const TextStyle(color: darkMuted),
      prefixIconColor: AppColors.mint,
      suffixIconColor: darkMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.mint,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          inherit: true,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.mint),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: AppColors.emeraldDark,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.mint
              : darkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.mint
              : darkMuted,
          fontSize: 12,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        inherit: true,
        color: AppColors.navy,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        inherit: true,
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        inherit: true,
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        inherit: true,
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        inherit: true,
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
    ),
  );
}

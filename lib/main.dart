import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_expense_tracker/ui/blocs/transaction/transaction_cubit.dart';
import 'package:personal_expense_tracker/ui/design_system/theme.dart';

import 'data/services/transaction_service.dart';
import 'firebase_options.dart';
import 'ui/blocs/auth/auth_cubit.dart';
import 'ui/blocs/theme/theme_cubit.dart';
import 'ui/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
            theme: DesignSystem.lightTheme,
            darkTheme: DesignSystem.darkTheme,
            themeMode: themeMode,
            themeAnimationDuration: Duration.zero,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

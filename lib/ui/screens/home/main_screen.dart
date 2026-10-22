
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/transaction_service.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    AnalyticsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocProvider(
      create: (_) => TransactionCubit(
        TransactionService(),
      )..listenToTransactions(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  if (index == _selectedIndex) return;

                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: colors.surface,
                surfaceTintColor: Colors.transparent,
                indicatorColor: colors.primary.withValues(alpha: 0.12),
                elevation: 0,
                height: 72,
                labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_outlined,
                      color: colors.onSurfaceVariant,
                      size: 23,
                    ),
                    selectedIcon: Icon(
                      Icons.home_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.insert_chart_outlined_rounded,
                      color: colors.onSurfaceVariant,
                      size: 23,
                    ),
                    selectedIcon: Icon(
                      Icons.insert_chart_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline_rounded,
                      color: colors.onSurfaceVariant,
                      size: 23,
                    ),
                    selectedIcon: Icon(
                      Icons.person_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/presentation/views/accounts_view.dart';
import 'package:money_manager/presentation/views/add_transaction_view.dart';
import 'package:money_manager/presentation/views/analytics_view.dart';
import 'package:money_manager/presentation/views/dashboard_view.dart';
import 'package:money_manager/presentation/views/report_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    DashboardView(),
    ReportView(),
    AnalyticsView(),
    AccountsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          // accounts tab has its own FAB inside AccountsView
          ? FloatingActionButton(
              heroTag: 'home_fab',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AddTransactionView()),
              ),
              backgroundColor: AppTheme.primaryColor,
              shape: const CircleBorder(),
              child:
                  const Icon(Icons.add_rounded, size: 28, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_rounded),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }
}

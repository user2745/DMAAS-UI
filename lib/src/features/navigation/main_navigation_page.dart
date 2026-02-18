import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../auth/view/login_page.dart';
import '../board/view/task_board_page.dart';
import '../board/cubit/task_board_cubit.dart';
import '../purchase/cubit/purchase_cubit.dart';
import '../purchase/cubit/purchase_state.dart';
import '../purchase/view/paywall_page.dart';
import '../boost/cubit/boost_cubit.dart';
import '../boost/cubit/boost_state.dart';
import '../today/today_tasks_page.dart';
import '../tasks_list/view/tasks_list_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      // Weekly Activities tab - reload fields in case they were updated
      context.read<TaskBoardCubit>().loadFields();
      context.read<TaskBoardCubit>().loadTasks();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PurchaseCubit, PurchaseState>(
      listenWhen: (prev, curr) =>
          !prev.hasHitLimit && curr.hasHitLimit && !curr.isPurchased,
      listener: (context, state) {
        PaywallPage.show(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'DMAAS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        actions: [
          // ⚡ Credit badge
          BlocBuilder<BoostCubit, BoostState>(
            builder: (context, boostState) {
              if (!boostState.creditsLoaded) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFBB86FC).withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${boostState.credits}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFBB86FC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState.status == AuthStatus.authenticated) {
                // Show account icon with dropdown when logged in
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.account_circle),
                    tooltip: 'Account',
                    onSelected: (value) {
                      if (value == 'signout') {
                        context.read<AuthCubit>().signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          authState.user?.email ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC9D1D9),
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20, color: Color(0xFF8B949E)),
                            SizedBox(width: 12),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Show account icon that navigates to login when not logged in
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                    icon: const Icon(Icons.account_circle_outlined),
                    tooltip: 'Sign In',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_week), text: 'Board'),
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.task_alt), text: 'List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TaskBoardPage(),
          TodayTasksPage(),
          TasksListPage(),
        ],
      ),
      ),
    );
  }
}

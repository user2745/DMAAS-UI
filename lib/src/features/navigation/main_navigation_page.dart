import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../board/view/task_board_page.dart';
import '../board/cubit/task_board_cubit.dart';
import '../today/today_tasks_page.dart';
import '../tasks_list/view/tasks_list_page.dart';
import '../tasks_list/cubit/tasks_list_cubit.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/view/login_page.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DMAAS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Decision Making & Activities Accounting System',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.2),
                    ),
                  ],
                ),
                actions: [
                  if (authState.user != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
                        child: Text(
                          authState.user!['email'] ?? '',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ),
                    ),
                  if (authState.isAuthenticated)
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        // Reload tasks in anonymous mode
                        context.read<TaskBoardCubit>().loadTasks();
                        context.read<TasksListCubit>().loadInitialData();
                      },
                      tooltip: 'Logout',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.login),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                        // After returning, refresh tasks (either logged in or still anonymous)
                        context.read<TaskBoardCubit>().loadTasks();
                        context.read<TasksListCubit>().loadInitialData();
                      },
                      tooltip: 'Sign in',
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.view_week), text: 'Weekly Activities'),
                    Tab(icon: Icon(Icons.today), text: "Today's Tasks"),
                    Tab(icon: Icon(Icons.task_alt), text: 'Tasks List'),
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
            );
      },
    );
  }
}

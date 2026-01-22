import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../board/view/task_board_page.dart';
import '../board/cubit/task_board_cubit.dart';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_week), text: 'Weekly Activities'),
            Tab(icon: Icon(Icons.today), text: "Today's Activities"),
            Tab(icon: Icon(Icons.task_alt), text: 'Activities List'),
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
  }
}

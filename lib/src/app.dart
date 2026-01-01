import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/board/cubit/task_board_cubit.dart';
import 'features/board/cubit/search_cubit.dart';
import 'features/board/data/mock_tasks.dart';
import 'features/navigation/main_navigation_page.dart';
import 'theme/app_theme.dart';

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskBoardCubit>(
          create: (_) => TaskBoardCubit(seedTasks: mockTasks),
        ),
        BlocProvider<SearchCubit>(create: (_) => SearchCubit()),
      ],
      child: MaterialApp(
        title: 'DMAAS - Decision Making & Activities Accounting System',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationPage(),
      ),
    );
  }
}

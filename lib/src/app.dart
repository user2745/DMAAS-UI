import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/board/cubit/task_board_cubit.dart';
import 'features/board/cubit/search_cubit.dart';
import 'features/board/data/task_api_service.dart';
import 'features/tasks_list/cubit/tasks_list_cubit.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_api_service.dart';
import 'features/navigation/main_navigation_page.dart';
import 'theme/app_theme.dart';

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({super.key, required this.anonymousId});

  final String anonymousId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(AuthApiService()),
        ),
        BlocProvider<TaskBoardCubit>(
          create: (context) => TaskBoardCubit(
            apiService: TaskApiService(
              authTokenProvider: () => context.read<AuthCubit>().state.token,
              anonymousIdProvider: () => anonymousId,
            ),
          )..loadTasks(),
        ),
        BlocProvider<SearchCubit>(create: (_) => SearchCubit()),
        BlocProvider<TasksListCubit>(
          create: (context) => TasksListCubit(
            taskApiService: TaskApiService(
              authTokenProvider: () => context.read<AuthCubit>().state.token,
              anonymousIdProvider: () => anonymousId,
            ),
          )..loadInitialData(),
        ),
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

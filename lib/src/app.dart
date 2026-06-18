import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/board/cubit/task_board_cubit.dart';
import 'features/board/cubit/search_cubit.dart';
import 'features/board/data/task_api_service.dart';
import 'features/tasks_list/cubit/tasks_list_cubit.dart';
import 'features/tasks_list/data/field_api_service.dart';
import 'features/navigation/main_navigation_page.dart';
import 'features/agent/cubit/agent_cubit.dart';
import 'features/agent/data/agent_service.dart';
import 'features/agent/data/webhook_dispatcher.dart';
import 'features/boost/cubit/boost_cubit.dart';
import 'features/boost/data/boost_service.dart';
import 'features/preferences/cubit/preferences_cubit.dart';
import 'features/preferences/data/preferences_api_service.dart';
import 'theme/app_theme.dart';

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({
    super.key,
    this.authRepository,
    this.taskApiService,
    this.fieldApiService,
    this.boostService,
    this.agentService,
    this.preferencesApiService,
  });

  final AuthRepository? authRepository;
  final TaskApiService? taskApiService;
  final FieldApiService? fieldApiService;
  final BoostService? boostService;
  final AgentService? agentService;
  final PreferencesApiService? preferencesApiService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(
            authRepository: authRepository ?? AuthRepository(),
          ),
        ),
        BlocProvider<TaskBoardCubit>(
          create: (context) {
            final webhook = WebhookDispatcher();
            return TaskBoardCubit(
              apiService: taskApiService ?? TaskApiService(
                tokenProvider: context.read<AuthCubit>().getIdToken,
                webhookDispatcher: webhook,
              ),
              fieldApiService: fieldApiService ?? FieldApiService(
                tokenProvider: context.read<AuthCubit>().getIdToken,
              ),
            )..loadTasks();
          },
        ),
        BlocProvider<SearchCubit>(create: (_) => SearchCubit()),
        BlocProvider<BoostCubit>(
          create: (context) => BoostCubit(
            boostService: boostService ?? BoostService(
              tokenProvider: context.read<AuthCubit>().getIdToken,
            ),
          ),
        ),
        BlocProvider<AgentCubit>(
          create: (context) => AgentCubit(
            agentService: agentService ?? AgentService(
              tokenProvider: context.read<AuthCubit>().getIdToken,
            ),
          ),
        ),
        BlocProvider<PreferencesCubit>(
          create: (context) => PreferencesCubit(
            apiService: preferencesApiService ?? PreferencesApiService(
              tokenProvider: context.read<AuthCubit>().getIdToken,
            ),
          )..load(),
        ),
        BlocProvider<TasksListCubit>(
          create: (context) {
            final webhook = WebhookDispatcher();
            return TasksListCubit(
              taskApiService: taskApiService ?? TaskApiService(
                tokenProvider: context.read<AuthCubit>().getIdToken,
                webhookDispatcher: webhook,
              ),
              fieldApiService: fieldApiService ?? FieldApiService(
                tokenProvider: context.read<AuthCubit>().getIdToken,
              ),
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'Activities',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationPage(),
      ),
    );
  }
}

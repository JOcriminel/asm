import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'tabs/tasks_manager_tab.dart';

class TasksAdminScreen extends StatelessWidget {
  const TasksAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const TasksManagerTab(),
    );
  }
}

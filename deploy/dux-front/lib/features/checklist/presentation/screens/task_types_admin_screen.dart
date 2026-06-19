import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'tabs/types_manager_tab.dart';

class TaskTypesAdminScreen extends StatelessWidget {
  const TaskTypesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Task Types'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const TypesManagerTab(),
    );
  }
}

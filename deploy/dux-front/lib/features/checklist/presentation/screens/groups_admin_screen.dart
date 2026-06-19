import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dux_front/core/widgets/dux_app_bar_title.dart';
import 'tabs/groups_manager_tab.dart';

class GroupsAdminScreen extends StatelessWidget {
  const GroupsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DuxAppBarTitle(title: 'Groups & Families'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const GroupsManagerTab(),
    );
  }
}

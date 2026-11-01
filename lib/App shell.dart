import 'package:flutter/material.dart';

import 'Add task screen.dart';
import 'Home screen.dart';

/// Каркас приложения с нижним меню.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _onTaskCreated() {
    setState(() => _index = 0);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Дело добавлено')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Экран пересоздаётся при переключении, поэтому главный каждый раз
      // заново читает список из хранилища.
      body: _index == 0
          ? const HomeScreen()
          : AddTaskScreen(onCreated: _onTaskCreated),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Добавить',
          ),
        ],
      ),
    );
  }
}
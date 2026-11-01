import 'package:flutter/material.dart';

import 'Task card.dart';
import 'TaskSevice.dart';
import 'TaskRepository.dart';

const _statusOrder = {
  TaskStatus.inProgress: 0,
  TaskStatus.pending: 1,
  TaskStatus.done: 2,
};

int _compareTasks(Task a, Task b) {
  final byStatus = _statusOrder[a.status]!.compareTo(_statusOrder[b.status]!);
  return byStatus != 0 ? byStatus : a.dateTime.compareTo(b.dateTime);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repo = TaskRepository();
  final _service = TaskService();
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Статус мог измениться кнопкой в уведомлении, пока приложение было в фоне
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final tasks = await _repo.getAll();
    tasks.sort(_compareTasks);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = _tasks.where((t) => t.status != TaskStatus.done).toList();
    final upcoming = active.where((t) => t.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final next = upcoming.isEmpty ? null : upcoming.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои дела'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _Summary(activeCount: active.length, next: next),
        ),

      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _tasks.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 160),
            Center(child: Text('Пока нет дел')),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final task = _tasks[i];
              return TaskCard(
                task: task,
                onStatusChanged: (status) async {
                  await _service.update(task.copyWith(status: status));
                  await _load();
                },
                onDelete: () async {
                  await _service.delete(task.id);
                  setState(() => _tasks.removeWhere((t) => t.id == task.id));
                },
              );
            },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.activeCount, required this.next});

  final int activeCount;
  final Task? next;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final nextTask = next;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Активных дел: $activeCount', style: style),
            Text(
              nextTask == null
                  ? 'Ближайших напоминаний нет'
                  : 'Ближайшее: ${formatDateTime(nextTask.dateTime)} · ${nextTask.title}',
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskRepository {
  static const _tasksKey = 'tasks';
  static const _nextIdKey = 'tasks_next_id';

  Future<Task> create({
    required String title,
    String description = '',
    required DateTime dateTime,
    TaskStatus status = TaskStatus.pending, // новое
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Название задачи не может быть пустым');
    }

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_nextIdKey) ?? 1;

    final task = Task(
      id: id,
      title: title.trim(),
      description: description.trim(),
      dateTime: dateTime,
      status: status, // новое
    );

    final tasks = await getAll();
    await _save([...tasks, task]);
    await prefs.setInt(_nextIdKey, id + 1);
    return task;
  }

  Future<List<Task>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task?> getById(int id) async {
    final tasks = await getAll();
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> update(Task task) async {
    final tasks = await getAll();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      throw StateError('Задача ${task.id} не найдена');
    }
    tasks[index] = task;
    await _save(tasks);
  }

  Future<bool> delete(int id) async {
    final tasks = await getAll();
    final before = tasks.length;
    tasks.removeWhere((t) => t.id == id);
    if (tasks.length == before) return false;
    await _save(tasks);
    return true;
  }

  Future<void> _save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }
}

enum TaskStatus { pending, inProgress, done }

class Task {
  final int id;
  final String title;
  final String description;
  final DateTime dateTime;
  final TaskStatus status;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.status = TaskStatus.pending,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    TaskStatus? status,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dateTime: dateTime ?? this.dateTime,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'status': status.name,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    dateTime: DateTime.parse(json['dateTime'] as String),
    status: TaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
      orElse: () => TaskStatus.pending,
    ),
  );
}
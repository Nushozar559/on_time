import 'NotitficationSevice.dart';
import 'TaskRepository.dart';

class TaskService {
  final _repo = TaskRepository();
  final _notifications = NotificationService.instance;

  Future<Task> create({
    required String title,
    String description = '',
    required DateTime dateTime,
    TaskStatus status = TaskStatus.pending,
  }) async {
    final task = await _repo.create(
      title: title,
      description: description,
      dateTime: dateTime,
      status: status,
    );
    if (task.status != TaskStatus.done) {
      await _notifications.schedule(task);
    }
    return task;
  }

  Future<void> update(Task task) async {
    await _repo.update(task);
    await _notifications.cancel(task.id);
    if (task.status != TaskStatus.done) {
      await _notifications.schedule(task);
    }
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _notifications.cancel(id);
  }
}
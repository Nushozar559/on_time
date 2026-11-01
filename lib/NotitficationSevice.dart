import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'TaskRepository.dart';
import 'TaskSevice.dart';

// Подключите свои файлы с моделью и репозиторием, например:
 //import '../models/task.dart';
 //import '../repositories/task_repository.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tasks';
  static const _channelName = 'Задачи';
  static const _iosCategory = 'task_category';
  static const actionDone = 'done';
  static const _iosLimit = 64;

  Future<void> init() async {
    // База часовых поясов нужна, т.к. zonedSchedule принимает TZDateTime.
    // Используем UTC: для разовых уведомлений момент времени остаётся
    // тем же, который выбрал пользователь.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategory,
          actions: [DarwinNotificationAction.plain(actionDone, 'Выполнено')],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Планирует уведомление для задачи. Id уведомления = id задачи.
  Future<void> schedule(Task task) async {
    final when = tz.TZDateTime.from(task.dateTime, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: task.id,
      title: task.title,
      body: task.description.isEmpty ? null : task.description,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              actionDone,
              'Выполнено',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: _iosCategory,
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id.toString(),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id:id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Пересобирает очередь: только невыполненные задачи в будущем,
  /// ближайшие 64 (лимит iOS). Вызывайте при запуске приложения.
  Future<void> rescheduleAll(List<Task> tasks) async {
    final now = DateTime.now();
    final upcoming = tasks
        .where((t) => t.status != TaskStatus.done && t.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    await _plugin.cancelAll();
    for (final task in upcoming.take(_iosLimit)) {
      await schedule(task);
    }
  }
}

/// Обработка нажатий на уведомление и его кнопки (приложение запущено).
Future<void> handleNotificationResponse(NotificationResponse response) async {
  final id = int.tryParse(response.payload ?? '');
  if (id == null) return;

  if (response.actionId == NotificationService.actionDone) {
    final repo = TaskRepository();
    final task = await repo.getById(id);
    if (task != null) {
      await repo.update(task.copyWith(status: TaskStatus.done));
    }
  } else {
    // Обычное нажатие на уведомление: здесь можно открыть экран задачи.
  }
}

/// Обработка для закрытого приложения. Должна быть top-level функцией.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  handleNotificationResponse(response);
}
import 'package:flutter/material.dart';

import 'App shell.dart';
import 'NotitficationSevice.dart';
import 'TaskRepository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService.instance;
  await notifications.init();
  await notifications.requestPermissions();

  // Пересобираем очередь при каждом запуске (лимит iOS в 64 уведомления,
  // плюс подхватываются задачи, изменённые в фоне)
  final tasks = await TaskRepository().getAll();
  await notifications.rescheduleAll(tasks);

  runApp(MaterialApp
    (
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB236DF),
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: AppShell()
    )
  );
}
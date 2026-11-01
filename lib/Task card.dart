import 'package:flutter/material.dart';
import 'package:on_time/TaskSevice.dart';


import 'TaskRepository.dart';

extension TaskStatusUi on TaskStatus {
  String get label => switch (this) {
    TaskStatus.pending => 'Ожидает',
    TaskStatus.inProgress => 'Выполняется',
    TaskStatus.done => 'Выполнено',
  };

  Color get color => switch (this) {
    TaskStatus.pending => Colors.red,
    TaskStatus.inProgress => Colors.orange,
    TaskStatus.done => Colors.green,
  };
}

String formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}.${two(dt.month)}.${dt.year} '
      '${two(dt.hour)}:${two(dt.minute)}';
}


class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onDelete,required this.onStatusChanged});

  final Task task;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = task.status.color;
    final isDone = task.status == TaskStatus.done;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusDropdown(status: task.status, onChanged: onStatusChanged),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  formatDateTime(task.dateTime),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )

              ),
            ),
            ElevatedButton(
              onPressed: () {
                onDelete();
              },
              child: Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                elevation: 0,
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({
    super.key,
    required this.status,
    required this.onChanged,
  });

  final TaskStatus status;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Semantics(
      label: 'Статус: ${status.label}',
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 2, top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TaskStatus>(
            value: status,
            isDense: true,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.arrow_drop_down, color: color),
            // Кнопка узкая (кружок + стрелка), поэтому ширину
            // раскрытого списка задаём отдельно, иначе текст обрежется.
            menuWidth: 170,
            onChanged: (s) {
              if (s != null && s != status) onChanged(s);
            },
            // На самой плашке: только цветной кружок, без текста
            selectedItemBuilder: (_) => [
              for (final s in TaskStatus.values)
                Center(child: Icon(Icons.circle, size: 14, color: s.color)),
            ],
            // В раскрытом списке: кружок и название статуса
            items: [
              for (final s in TaskStatus.values)
                DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: s.color),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
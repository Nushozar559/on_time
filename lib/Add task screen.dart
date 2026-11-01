import 'package:flutter/material.dart';


import 'Task card.dart';
import 'TaskRepository.dart';
import 'TaskSevice.dart';


class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, required this.onCreated});

  /// Вызывается после успешного сохранения (например, чтобы перейти на главный экран).
  final VoidCallback onCreated;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _service = TaskService();

  TaskStatus _status = TaskStatus.pending;
  DateTime? _dateTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();
    final current = _dateTime;
    final initial = (current != null && current.isAfter(now)) ? current : now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // остаёмся на экране

    setState(() => _saving = true);
    try {
      await _service.create(
        title: _titleController.text,
        dateTime: _dateTime!,
        status: _status,
      );
      if (!mounted) return;
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Новое дело')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Название дела',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Время напоминания
            Text('Время напоминания', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            FormField<DateTime>(
              validator: (value) {
                if (value == null) return 'Выберите время напоминания';
                if (!value.isAfter(DateTime.now())) return 'Это время уже прошло';
                return null;
              },
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.alarm),
                    label: Text(
                      _dateTime == null
                          ? 'Выбрать дату и время'
                          : formatDateTime(_dateTime!),
                    ),
                    onPressed: () async {
                      final picked = await _pickDateTime();
                      if (picked == null) return;
                      setState(() => _dateTime = picked);
                      field.didChange(picked);
                    },
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        field.errorText!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}
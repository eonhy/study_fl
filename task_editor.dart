import 'dart:math';

import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});

  final Task? task;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late Priority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title);
    _notes = TextEditingController(text: task?.notes);
    _priority = task?.priority ?? Priority.normal;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (mounted && selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final original = widget.task;
    final now = DateTime.now().toUtc();
    Navigator.of(context).pop(
      Task(
        id: original?.id ??
            '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
        title: _title.text.trim(),
        notes: _notes.text.trim(),
        priority: _priority,
        createdAt: original?.createdAt ?? now,
        dueDate: _dueDate,
        completed: original?.completed ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = _dueDate;
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? '새 할 일' : '할 일 수정')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: widget.task == null,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? '제목을 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: const InputDecoration(labelText: '메모'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Priority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: '우선순위'),
                    items: [
                      for (final priority in Priority.values)
                        DropdownMenuItem(
                          value: priority,
                          child: Text(priority.label),
                        ),
                    ],
                    onChanged: (priority) {
                      if (priority != null) {
                        setState(() => _priority = priority);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            dueDate == null
                                ? '마감일 선택'
                                : MaterialLocalizations.of(context)
                                      .formatMediumDate(dueDate),
                          ),
                        ),
                      ),
                      if (dueDate != null)
                        IconButton(
                          tooltip: '마감일 지우기',
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _submit, child: const Text('저장')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/task_store.dart';
import '../models/task.dart';
import 'task_editor.dart';

class TaskBoard extends StatefulWidget {
  const TaskBoard({super.key});

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  final _store = TaskStore();
  final _search = TextEditingController();
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      final tasks = await _store.load();
      if (mounted) setState(() => _tasks = tasks);
    } on Exception {
      if (mounted) setState(() => _loadFailed = true);
    } on TypeError {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(List<Task> updated) async {
    if (_saving || _loading || _loadFailed) return;
    setState(() => _saving = true);

    try {
      await _store.save(updated);
      if (mounted) setState(() => _tasks = updated);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit([Task? task]) async {
    final edited = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => TaskEditor(task: task)),
    );
    if (!mounted || edited == null) return;
    await _save([
      for (final existing in _tasks)
        if (existing.id == edited.id) edited else existing,
      if (task == null) edited,
    ]);
  }

  Future<void> _delete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('할 일을 삭제할까요?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _save(_tasks.where((item) => item.id != task.id).toList());
  }

  Future<void> _toggle(Task task) {
    return _save([
      for (final item in _tasks)
        if (item.id == task.id) item.toggleCompletion() else item,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dayline')),
      floatingActionButton: _loading || _loadFailed
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('할 일 추가'),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('저장된 할 일을 불러오지 못했어요.'),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final query = _search.text.trim().toLowerCase();
    final visible = _tasks
        .where((task) => _filter.matches(task) && task.matchesQuery(query))
        .toList()
      ..sort(Task.compare);
    final completed = _tasks.where((task) => task.completed).length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressCard(total: _tasks.length, completed: completed),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '제목 또는 메모 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in TaskFilter.values)
                      ChoiceChip(
                        label: Text(filter.label),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(semanticsLabel: '저장 중'),
                  ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _tasks.isEmpty
                      ? '할 일 추가 버튼을 눌러 시작해 보세요.'
                      : '검색어 또는 필터에 맞는 할 일이 없어요.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final task = visible[index];
                return _TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  onToggle: _saving ? null : () => _toggle(task),
                  onEdit: _saving ? null : () => _edit(task),
                  onDelete: _saving ? null : () => _delete(task),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '남은 할 일 ${total - completed}개',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '전체 ${total}개 중 ${completed}개 완료',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: '할 일 완료율',
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = task.dueDate;
    final today = DateUtils.dateOnly(DateTime.now());
    final overdue = !task.completed &&
        dueDate != null &&
        dueDate.isBefore(today);
    final details = [
      '우선순위 ${task.priority.label}',
      if (dueDate != null)
        '${overdue ? '기한 지남' : '마감'} '
            '${MaterialLocalizations.of(context).formatMediumDate(dueDate)}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        onTap: onEdit,
        leading: Checkbox(
          value: task.completed,
          semanticLabel: '${task.title} 완료',
          onChanged: onToggle == null ? null : (_) => onToggle!(),
        ),
        title: Text(
          task.title,
          style: task.completed
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.join(' · '),
                style: overdue ? TextStyle(color: theme.colorScheme.error) : null,
              ),
              if (task.notes.isNotEmpty)
                Text(
                  task.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: '할 일 삭제',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

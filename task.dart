enum Priority {
  low('낮음'),
  normal('보통'),
  high('높음');

  const Priority(this.label);

  final String label;
}

enum TaskFilter {
  all('전체'),
  open('진행 중'),
  completed('완료');

  const TaskFilter(this.label);

  final String label;

  bool matches(Task task) => switch (this) {
    TaskFilter.all => true,
    TaskFilter.open => !task.completed,
    TaskFilter.completed => task.completed,
  };
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.completed = false,
  });

  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool completed;

  factory Task.fromJson(Map<String, dynamic> json) {
    final dueDate = json['dueDate'] as String?;
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String,
      priority: Priority.values.byName(json['priority'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'priority': priority.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'dueDate': dueDate?.toIso8601String().split('T').first,
    'completed': completed,
  };

  Task toggleCompletion() => Task(
    id: id,
    title: title,
    notes: notes,
    priority: priority,
    createdAt: createdAt,
    dueDate: dueDate,
    completed: !completed,
  );

  bool matchesQuery(String query) {
    return title.toLowerCase().contains(query) ||
        notes.toLowerCase().contains(query);
  }

  static int compare(Task a, Task b) {
    if (a.completed != b.completed) return a.completed ? 1 : -1;
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue != null && bDue != null) {
      final byDate = aDue.compareTo(bDue);
      if (byDate != 0) return byDate;
    } else if (aDue != bDue) {
      return aDue == null ? 1 : -1;
    }
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) return byPriority;
    final byCreation = b.createdAt.compareTo(a.createdAt);
    return byCreation == 0 ? a.id.compareTo(b.id) : byCreation;
  }
}

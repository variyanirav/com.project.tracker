import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../data/database/app_database.dart';
import '../providers/project_provider.dart';
import '../providers/todo_provider.dart';
import '../routes/app_router.dart';
import '../widgets/dialogs/upsert_todo_dialog.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _visibleCount = _pageSize;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todosAsync = ref.watch(todoItemsProvider);
    final todoCountAsync = ref.watch(openTodoCountProvider);
    final completedCountAsync = ref.watch(completedTodoCountProvider);

    return CustomScaffold(
      activeRoute: AppRouter.todoList,
      child: Column(
        children: [
          _TopBar(
            searchController: _searchController,
            onCreatePressed: _showCreateDialog,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To-Do List', style: AppTextStyles.heading2),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Capture reminders, ideas, follow-ups, and future tasks.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'To Do',
                          valueAsync: todoCountAsync,
                          accent: AppColors.brandPrimary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacing16),
                      Expanded(
                        child: _StatCard(
                          title: 'Completed',
                          valueAsync: completedCountAsync,
                          accent: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing24),
                  _FilterBar(
                    selectedStatus: _statusFilter,
                    selectedPriority: _priorityFilter,
                    onStatusChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                        _visibleCount = _pageSize;
                      });
                    },
                    onPriorityChanged: (value) {
                      setState(() {
                        _priorityFilter = value;
                        _visibleCount = _pageSize;
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  todosAsync.when(
                    data: (todos) {
                      final projects = ref.watch(projectsProvider).value ?? [];
                      final filtered = _applyFilters(todos);
                      final visible = filtered.take(_visibleCount).toList();
                      final hasMore = filtered.length > visible.length;

                      if (filtered.isEmpty) {
                        return _EmptyTodoState(
                          onCreatePressed: _showCreateDialog,
                        );
                      }

                      return Column(
                        children: [
                          ...visible.map(
                            (todo) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.spacing12,
                              ),
                              child: _TodoListItem(
                                todo: todo,
                                projectName: _projectNameById(
                                  projects,
                                  todo.linkedProjectId,
                                ),
                                onToggleDone: () => _toggleDone(todo),
                                onQuickInProgress: () =>
                                    _updateStatus(todo, todoStatusInProgress),
                                onQuickSnooze: () => _updateStatus(
                                  todo,
                                  todoStatusSnoozed,
                                  snoozedUntil: DateTime.now()
                                      .add(const Duration(days: 1))
                                      .toUtc(),
                                ),
                                onEdit: () => _showEditDialog(todo),
                                onDelete: () => _deleteTodo(todo.id),
                              ),
                            ),
                          ),
                          if (hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleCount += _pageSize;
                                  });
                                },
                                child: Text(
                                  'Load More (${filtered.length - visible.length} left)',
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Failed to load to-do items: $err')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TodoItemData> _applyFilters(List<TodoItemData> todos) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = todos.where((todo) {
      final statusMatches = _statusFilter == 'all'
          ? true
          : todo.status == _statusFilter;
      final priorityMatches = _priorityFilter == 'all'
          ? true
          : todo.priority == _priorityFilter;

      final title = todo.title.toLowerCase();
      final description = todo.description.toLowerCase();
      final queryMatches = query.isEmpty
          ? true
          : title.contains(query) || description.contains(query);

      return statusMatches && priorityMatches && queryMatches;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  String _projectNameById(List projects, String? projectId) {
    if (projectId == null) {
      return 'General';
    }

    try {
      final project = projects.firstWhere((p) => p.id == projectId);
      return project.name;
    } catch (_) {
      return 'General';
    }
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UpsertTodoDialog(
        onCreate: (params) async {
          await ref.read(createTodoProvider(params).future);
        },
        onUpdate: (params) async {
          await ref.read(updateTodoProvider(params).future);
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('To-do item created')));
    }
  }

  Future<void> _showEditDialog(TodoItemData todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UpsertTodoDialog(
        existingTodo: todo,
        onCreate: (params) async {
          await ref.read(createTodoProvider(params).future);
        },
        onUpdate: (params) async {
          await ref.read(updateTodoProvider(params).future);
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('To-do item updated')));
    }
  }

  Future<void> _deleteTodo(String id) async {
    await ref.read(deleteTodoProvider(id).future);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('To-do item deleted')));
    }
  }

  Future<void> _toggleDone(TodoItemData todo) async {
    await _updateStatus(
      todo,
      todo.status == todoStatusDone ? todoStatusOpen : todoStatusDone,
    );
  }

  Future<void> _updateStatus(
    TodoItemData todo,
    String status, {
    DateTime? snoozedUntil,
  }) async {
    await ref.read(
      updateTodoStatusProvider(
        UpdateTodoStatusParams(
          id: todo.id,
          status: status,
          snoozedUntil: snoozedUntil,
        ),
      ).future,
    );
  }
}

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onCreatePressed;

  const _TopBar({
    required this.searchController,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by title or description...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacing16),
          ElevatedButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add),
            label: const Text('Create To-Do'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selectedStatus;
  final String selectedPriority;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;

  const _FilterBar({
    required this.selectedStatus,
    required this.selectedPriority,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Wrap(
          spacing: AppConstants.spacing8,
          children: [
            _StatusChip(
              label: 'All',
              value: 'all',
              selectedValue: selectedStatus,
              onSelected: onStatusChanged,
            ),
            _StatusChip(
              label: 'Open',
              value: todoStatusOpen,
              selectedValue: selectedStatus,
              onSelected: onStatusChanged,
            ),
            _StatusChip(
              label: 'In Progress',
              value: todoStatusInProgress,
              selectedValue: selectedStatus,
              onSelected: onStatusChanged,
            ),
            _StatusChip(
              label: 'Done',
              value: todoStatusDone,
              selectedValue: selectedStatus,
              onSelected: onStatusChanged,
            ),
            _StatusChip(
              label: 'Snoozed',
              value: todoStatusSnoozed,
              selectedValue: selectedStatus,
              onSelected: onStatusChanged,
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: selectedPriority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: todoPriorityHigh, child: Text('High')),
              DropdownMenuItem(
                value: todoPriorityMedium,
                child: Text('Medium'),
              ),
              DropdownMenuItem(value: todoPriorityLow, child: Text('Low')),
            ],
            onChanged: (value) {
              if (value != null) {
                onPriorityChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final AsyncValue<int> valueAsync;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.valueAsync,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          valueAsync.when(
            data: (value) => Text(
              '$value',
              style: AppTextStyles.heading2.copyWith(color: accent),
            ),
            loading: () => const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              '-',
              style: AppTextStyles.heading2.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoListItem extends StatelessWidget {
  final TodoItemData todo;
  final String projectName;
  final VoidCallback onToggleDone;
  final VoidCallback onQuickInProgress;
  final VoidCallback onQuickSnooze;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoListItem({
    required this.todo,
    required this.projectName,
    required this.onToggleDone,
    required this.onQuickInProgress,
    required this.onQuickSnooze,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = todo.status == todoStatusDone;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onToggleDone,
            icon: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? AppColors.success : null,
            ),
          ),
          const SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (todo.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacing4),
                    child: Text(
                      todo.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppConstants.spacing8),
                Wrap(
                  spacing: AppConstants.spacing8,
                  runSpacing: AppConstants.spacing8,
                  children: [
                    _Tag(
                      text: _labelForPriority(todo.priority),
                      color: _priorityColor(todo.priority),
                    ),
                    _Tag(
                      text: _labelForStatus(todo.status),
                      color: _statusColor(todo.status),
                    ),
                    _Tag(text: projectName, color: AppColors.brandPrimary),
                    if (todo.dueDate != null)
                      _Tag(
                        text:
                            'Due ${todo.dueDate!.year}-${todo.dueDate!.month.toString().padLeft(2, '0')}-${todo.dueDate!.day.toString().padLeft(2, '0')}',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'in_progress':
                  onQuickInProgress();
                  break;
                case 'snooze':
                  onQuickSnooze();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'in_progress',
                child: Text('Move to In Progress'),
              ),
              PopupMenuItem(value: 'snooze', child: Text('Snooze 1 day')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForPriority(String value) {
    switch (value) {
      case todoPriorityHigh:
        return 'High';
      case todoPriorityLow:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String _labelForStatus(String value) {
    switch (value) {
      case todoStatusOpen:
        return 'Open';
      case todoStatusInProgress:
        return 'In Progress';
      case todoStatusDone:
        return 'Done';
      case todoStatusSnoozed:
        return 'Snoozed';
      default:
        return value;
    }
  }

  Color _priorityColor(String value) {
    switch (value) {
      case todoPriorityHigh:
        return AppColors.error;
      case todoPriorityLow:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case todoStatusDone:
        return AppColors.success;
      case todoStatusInProgress:
        return AppColors.brandPrimary;
      case todoStatusSnoozed:
        return AppColors.warning;
      default:
        return AppColors.darkTextSecondary;
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _EmptyTodoState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _EmptyTodoState({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.roundRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 54,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text('No to-do items found', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Try changing filters or create a new to-do item.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacing16),
          ElevatedButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add),
            label: const Text('Create To-Do'),
          ),
        ],
      ),
    );
  }
}

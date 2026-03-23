import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

const String todoStatusOpen = 'open';
const String todoStatusInProgress = 'in_progress';
const String todoStatusDone = 'done';
const String todoStatusSnoozed = 'snoozed';

const String todoPriorityLow = 'low';
const String todoPriorityMedium = 'medium';
const String todoPriorityHigh = 'high';

const List<String> todoStatuses = [
  todoStatusOpen,
  todoStatusInProgress,
  todoStatusDone,
  todoStatusSnoozed,
];

const List<String> todoPriorities = [
  todoPriorityLow,
  todoPriorityMedium,
  todoPriorityHigh,
];

final todoItemsProvider = FutureProvider<List<TodoItemData>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.todoItems)..orderBy([
        (t) => drift.OrderingTerm(
          expression: t.createdAt,
          mode: drift.OrderingMode.desc,
        ),
      ]))
      .get();
});

final openTodoCountProvider = FutureProvider<int>((ref) async {
  final todos = await ref.watch(todoItemsProvider.future);
  return todos.where((t) => t.status != todoStatusDone).length;
});

final completedTodoCountProvider = FutureProvider<int>((ref) async {
  final todos = await ref.watch(todoItemsProvider.future);
  return todos.where((t) => t.status == todoStatusDone).length;
});

final createTodoProvider = FutureProvider.family<void, CreateTodoParams>((
  ref,
  params,
) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now().toUtc();

  await db
      .into(db.todoItems)
      .insert(
        TodoItemsCompanion.insert(
          id: const Uuid().v4(),
          title: params.title.trim(),
          description: drift.Value(params.description.trim()),
          status: drift.Value(params.status),
          priority: drift.Value(params.priority),
          referenceUrl: drift.Value(
            params.referenceUrl?.trim().isEmpty == true
                ? null
                : params.referenceUrl?.trim(),
          ),
          linkedProjectId: drift.Value(params.linkedProjectId),
          dueDate: drift.Value(params.dueDate),
          snoozedUntil: drift.Value(params.snoozedUntil),
          createdAt: now,
          updatedAt: now,
        ),
      );

  ref.invalidate(todoItemsProvider);
  ref.invalidate(openTodoCountProvider);
  ref.invalidate(completedTodoCountProvider);
});

final updateTodoProvider = FutureProvider.family<void, UpdateTodoParams>((
  ref,
  params,
) async {
  final db = ref.watch(databaseProvider);

  await (db.update(db.todoItems)..where((t) => t.id.equals(params.id))).write(
    TodoItemsCompanion(
      title: drift.Value(params.title.trim()),
      description: drift.Value(params.description.trim()),
      status: drift.Value(params.status),
      priority: drift.Value(params.priority),
      referenceUrl: drift.Value(
        params.referenceUrl?.trim().isEmpty == true
            ? null
            : params.referenceUrl?.trim(),
      ),
      linkedProjectId: drift.Value(params.linkedProjectId),
      dueDate: drift.Value(params.dueDate),
      snoozedUntil: drift.Value(params.snoozedUntil),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    ),
  );

  ref.invalidate(todoItemsProvider);
  ref.invalidate(openTodoCountProvider);
  ref.invalidate(completedTodoCountProvider);
});

final updateTodoStatusProvider =
    FutureProvider.family<void, UpdateTodoStatusParams>((ref, params) async {
      final db = ref.watch(databaseProvider);

      await (db.update(
        db.todoItems,
      )..where((t) => t.id.equals(params.id))).write(
        TodoItemsCompanion(
          status: drift.Value(params.status),
          snoozedUntil: drift.Value(params.snoozedUntil),
          updatedAt: drift.Value(DateTime.now().toUtc()),
        ),
      );

      ref.invalidate(todoItemsProvider);
      ref.invalidate(openTodoCountProvider);
      ref.invalidate(completedTodoCountProvider);
    });

final deleteTodoProvider = FutureProvider.family<void, String>((
  ref,
  todoId,
) async {
  final db = ref.watch(databaseProvider);
  await (db.delete(db.todoItems)..where((t) => t.id.equals(todoId))).go();

  ref.invalidate(todoItemsProvider);
  ref.invalidate(openTodoCountProvider);
  ref.invalidate(completedTodoCountProvider);
});

class CreateTodoParams {
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? referenceUrl;
  final String? linkedProjectId;
  final DateTime? dueDate;
  final DateTime? snoozedUntil;

  CreateTodoParams({
    required this.title,
    required this.description,
    this.status = todoStatusOpen,
    this.priority = todoPriorityMedium,
    this.referenceUrl,
    this.linkedProjectId,
    this.dueDate,
    this.snoozedUntil,
  });
}

class UpdateTodoParams {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? referenceUrl;
  final String? linkedProjectId;
  final DateTime? dueDate;
  final DateTime? snoozedUntil;

  UpdateTodoParams({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.referenceUrl,
    this.linkedProjectId,
    this.dueDate,
    this.snoozedUntil,
  });
}

class UpdateTodoStatusParams {
  final String id;
  final String status;
  final DateTime? snoozedUntil;

  UpdateTodoStatusParams({
    required this.id,
    required this.status,
    this.snoozedUntil,
  });
}

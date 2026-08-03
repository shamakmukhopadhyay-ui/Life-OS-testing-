import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../objectives/logic/objectives_provider.dart';
import '../../data/task_model.dart';

/// Opens the create/edit form as a modal bottom sheet.
///
/// Pass [existing] to pre-fill the form for editing; leave it null to
/// create a new task. [onSubmit] receives the finished [Task] — the
/// caller decides whether that means `addTask` or `updateTask`.
///
/// This is the one place in the Tasks feature that reads from the
/// Objectives feature (to populate the "Linked Objective" dropdown) —
/// it only reads objective id/title pairs, never an Objective's full
/// data, and only at the Presentation layer, matching how the Home
/// Dashboard already reads across features.
Future<void> showTaskFormSheet({
  required BuildContext context,
  required void Function(Task) onSubmit,
  Task? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _TaskFormSheet(existing: existing, onSubmit: onSubmit),
    ),
  );
}

class _TaskFormSheet extends ConsumerStatefulWidget {
  const _TaskFormSheet({required this.onSubmit, this.existing});

  final Task? existing;
  final void Function(Task) onSubmit;

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;
  late TaskPriority _priority;
  TimeOfDay? _dueTime;
  String? _linkedObjectiveId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _pointsController = TextEditingController(
      text: existing != null ? existing.pointValue.toString() : '',
    );
    _priority = existing?.priority ?? TaskPriority.medium;
    _dueTime = existing?.dueTime != null
        ? TimeOfDay(
            hour: existing!.dueTime!.hour,
            minute: existing.dueTime!.minute,
          )
        : null;
    _linkedObjectiveId = existing?.linkedObjectiveId;
    // Bug fix (original): if the linked objective was deleted entirely since
    // this task was created, clear the stale reference now. Without this,
    // the dropdown below would open with a current value matching no item
    // in its list, which throws a Flutter assertion error.
    //
    // Bug fix (Sprint 6): objectivesProvider is now AsyncNotifierProvider,
    // so ref.read() returns AsyncValue<List<Objective>>, not List<Objective>.
    // AsyncValue has no .any() method — must unwrap with .valueOrNull first.
    if (_linkedObjectiveId != null &&
        !(ref
                .read(objectivesProvider)
                .valueOrNull
                ?.any((o) => o.id == _linkedObjectiveId) ??
            false)) {
      _linkedObjectiveId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.existing;
    final task = Task(
      id: existing?.id ?? generateLocalId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      linkedObjectiveId: _linkedObjectiveId,
      pointValue: int.tryParse(_pointsController.text.trim()) ?? 0,
      dueTime: _dueTime == null
          ? null
          : DateTime(now.year, now.month, now.day, _dueTime!.hour,
              _dueTime!.minute),
      priority: _priority,
      isCompleted: existing?.isCompleted ?? false,
    );

    widget.onSubmit(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    // Active + completed objectives are linkable; archived ones are
    // hidden from the whole app right now (per the Objectives feature's
    // current behavior), so they're excluded here too.
    final linkableObjectives = [
      ...ref.watch(activeObjectivesProvider),
      ...ref.watch(completedObjectivesProvider),
    ];

    // Bug fix: if this task is linked to an objective that still exists
    // but is archived (so it's not in linkableObjectives above), the
    // dropdown's current value would otherwise match no item and throw.
    // Surface it as an extra, clearly-labeled item instead of excluding
    // it outright.
    final linkedButArchived = _linkedObjectiveId == null
        ? null
        : ref.watch(archivedObjectivesProvider).where(
              (o) => o.id == _linkedObjectiveId,
            ).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'New Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name.substring(0, 1).toUpperCase() +
                              p.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'Point value'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Point value is required';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) return 'Enter a whole number';
                  if (parsed < 0) return 'Point value cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _linkedObjectiveId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Linked objective (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...linkableObjectives.map(
                    (o) => DropdownMenuItem<String?>(
                      value: o.id,
                      child: Text(o.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  // Bug fix: keeps the dropdown's current value valid
                  // when this task is linked to an archived objective.
                  if (linkedButArchived != null)
                    DropdownMenuItem<String?>(
                      value: linkedButArchived.id,
                      child: Text(
                        '${linkedButArchived.title} (archived)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _linkedObjectiveId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueTime == null
                          ? 'No due time set'
                          : 'Due: ${_dueTime!.format(context)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDueTime,
                    child: const Text('Pick time'),
                  ),
                  if (_dueTime != null)
                    TextButton(
                      onPressed: () => setState(() => _dueTime = null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: isEditing ? 'Save Changes' : 'Create Task',
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

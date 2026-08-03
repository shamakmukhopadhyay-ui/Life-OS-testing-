import 'package:flutter/material.dart';

import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/objective_model.dart';

/// Opens the create/edit form as a modal bottom sheet.
///
/// Pass [existing] to pre-fill the form for editing; leave it null to
/// create a brand-new objective. [onSubmit] receives the finished
/// [Objective] — the caller decides whether that means calling
/// `addObjective` or `updateObjective` on the notifier. This function
/// intentionally knows nothing about Riverpod or the repository, keeping
/// it a pure Presentation-layer concern.
Future<void> showObjectiveFormSheet({
  required BuildContext context,
  required void Function(Objective) onSubmit,
  Objective? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ObjectiveFormSheet(existing: existing, onSubmit: onSubmit),
    ),
  );
}

class _ObjectiveFormSheet extends StatefulWidget {
  const _ObjectiveFormSheet({required this.onSubmit, this.existing});

  final Objective? existing;
  final void Function(Objective) onSubmit;

  @override
  State<_ObjectiveFormSheet> createState() => _ObjectiveFormSheetState();
}

class _ObjectiveFormSheetState extends State<_ObjectiveFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;
  late ObjectiveCategory _category;
  late ObjectivePriority _priority;
  DateTime? _targetDate;

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
    _category = existing?.category ?? ObjectiveCategory.personal;
    _priority = existing?.priority ?? ObjectivePriority.medium;
    _targetDate = existing?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;
    final objective = Objective(
      id: existing?.id ?? generateLocalId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      pointValue: int.tryParse(_pointsController.text.trim()) ?? 0,
      status: existing?.status ?? ObjectiveStatus.active,
      targetDate: _targetDate,
      linkedTasksTotal: existing?.linkedTasksTotal ?? 0,
      linkedTasksCompleted: existing?.linkedTasksCompleted ?? 0,
    );

    widget.onSubmit(objective);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
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
                isEditing ? 'Edit Objective' : 'New Objective',
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
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ObjectiveCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ObjectiveCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name.substring(0, 1).toUpperCase() +
                              c.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ObjectivePriority>(
                initialValue: _priority,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ObjectivePriority.values
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _targetDate == null
                          ? 'No target date set'
                          : 'Target: ${_targetDate!.month}/${_targetDate!.day}/${_targetDate!.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickTargetDate,
                    child: const Text('Pick date'),
                  ),
                  if (_targetDate != null)
                    TextButton(
                      onPressed: () => setState(() => _targetDate = null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: isEditing ? 'Save Changes' : 'Create Objective',
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

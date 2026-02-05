import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';
import '../../../widgets/animated_focus_text_field.dart';

class CreateFieldDialog extends StatefulWidget {
  const CreateFieldDialog({super.key, this.initialField});

  final Field? initialField;

  @override
  State<CreateFieldDialog> createState() => _CreateFieldDialogState();
}

class _CreateFieldDialogState extends State<CreateFieldDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  FieldType _selectedType = FieldType.text;
  late TextEditingController _optionInputController;
  final List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialField?.name ?? '',
    );
    _selectedColor = widget.initialField?.color ?? fieldColors.first;
    _selectedType = widget.initialField?.type ?? FieldType.text;
    _optionInputController = TextEditingController();
    if (widget.initialField?.options != null) {
      _options.addAll(widget.initialField!.options);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _optionInputController.dispose();
    super.dispose();
  }

  void _addOption() {
    final option = _optionInputController.text.trim();
    if (option.isNotEmpty && !_options.contains(option)) {
      setState(() {
        _options.add(option);
        _optionInputController.clear();
      });
    }
  }

  void _removeOption(String option) {
    setState(() {
      _options.remove(option);
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialField == null ? 'Add Field' : 'Edit Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Design Language: Focus-animated input (200ms)
            AnimatedFocusTextField(
              controller: _nameController,
              labelText: 'Field Name',
              hintText: 'e.g., Priority, Category, Team',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FieldType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Field Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: FieldType.text, child: Text('Text')),
                DropdownMenuItem(
                  value: FieldType.singleSelect,
                  child: Text('Single Select'),
                ),
                DropdownMenuItem(value: FieldType.date, child: Text('Date')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            if (_selectedType == FieldType.singleSelect) ...[
              const SizedBox(height: 16),
              Text('Options', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AnimatedFocusTextField(
                      controller: _optionInputController,
                      hintText: 'Add option...',
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (_optionInputController.text.trim().isNotEmpty) {
                          _addOption();
                        }
                      },
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _optionInputController.text.trim().isEmpty
                        ? null
                        : _addOption,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_options.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _options.map((option) {
                    return Chip(
                      label: Text(option),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeOption(option),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a field name')),
              );
              return;
            }

            if (widget.initialField == null) {
              context.read<TasksListCubit>().createField(
                name: name,
                type: _selectedType,
                options: _options,
                color: _colorToHex(_selectedColor),
              );
            } else {
              context.read<TasksListCubit>().updateField(
                fieldId: widget.initialField!.id,
                name: name,
                color: _colorToHex(_selectedColor),
              );
            }

            Navigator.pop(context);
          },
          child: Text(widget.initialField == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

class FieldSelector extends StatelessWidget {
  const FieldSelector({
    super.key,
    required this.fields,
    required this.selectedFieldIds,
    required this.onFieldToggled,
    required this.onCreateField,
  });

  final List<Field> fields;
  final List<String> selectedFieldIds;
  final Function(String) onFieldToggled;
  final VoidCallback onCreateField;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: onCreateField,
              icon: const Icon(Icons.add),
              label: const Text('New Field'),
            ),
          ),
          ...fields.map((field) {
            final isSelected = selectedFieldIds.contains(field.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (_) => onFieldToggled(field.id),
                avatar: CircleAvatar(backgroundColor: field.color),
                label: Text(field.name),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: field.color.withOpacity(0.3), width: 1),
                selectedColor: field.color.withOpacity(0.2),
              ),
            );
          }),
        ],
      ),
    );
  }
}

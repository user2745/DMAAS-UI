import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/tasks_list_cubit.dart';
import '../models/field.dart';

class CreateFieldDialog extends StatefulWidget {
  const CreateFieldDialog({
    super.key,
    this.initialField,
  });

  final Field? initialField;

  @override
  State<CreateFieldDialog> createState() => _CreateFieldDialogState();
}

class _CreateFieldDialogState extends State<CreateFieldDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  FieldType _selectedType = FieldType.text;
  late TextEditingController _optionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialField?.name ?? '',
    );
    _selectedColor = widget.initialField?.color ?? fieldColors.first;
    _selectedType = widget.initialField?.type ?? FieldType.text;
    _optionsController = TextEditingController(
      text: widget.initialField?.options.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialField == null ? 'Add Field' : 'Edit Field',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g., Priority, Category, Team',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FieldType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Field Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: FieldType.text, child: Text('Text')),
                DropdownMenuItem(value: FieldType.singleSelect, child: Text('Single Select')),
                DropdownMenuItem(value: FieldType.date, child: Text('Date')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            if (_selectedType == FieldType.singleSelect) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _optionsController,
                decoration: InputDecoration(
                  labelText: 'Options (comma separated)',
                  hintText: 'e.g., Low, Medium, High',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: fieldColors.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
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

            final options = _optionsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            if (widget.initialField == null) {
              context.read<TasksListCubit>().createField(
                    name: name,
                    type: _selectedType,
                    options: options,
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
                side: BorderSide(
                  color: field.color.withOpacity(0.3),
                  width: 1,
                ),
                selectedColor: field.color.withOpacity(0.2),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

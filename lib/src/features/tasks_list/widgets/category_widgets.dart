import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/tasks_list_cubit.dart';
import '../models/category.dart';

class CreateCategoryDialog extends StatefulWidget {
  const CreateCategoryDialog({
    super.key,
    this.initialCategory,
  });

  final Category? initialCategory;

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory?.name ?? '',
    );
    _selectedColor = widget.initialCategory?.color ?? categoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialCategory == null ? 'Create Category' : 'Edit Category',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categoryColors.map((color) {
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
                const SnackBar(content: Text('Please enter a category name')),
              );
              return;
            }

            if (widget.initialCategory == null) {
              context.read<TasksListCubit>().createCategory(
                    name: name,
                    color: _colorToHex(_selectedColor),
                  );
            } else {
              context.read<TasksListCubit>().updateCategory(
                    categoryId: widget.initialCategory!.id,
                    name: name,
                    color: _colorToHex(_selectedColor),
                  );
            }

            Navigator.pop(context);
          },
          child: Text(widget.initialCategory == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategoryToggled,
    required this.onCreateCategory,
  });

  final List<Category> categories;
  final List<String> selectedCategoryIds;
  final Function(String) onCategoryToggled;
  final VoidCallback onCreateCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: onCreateCategory,
              icon: const Icon(Icons.add),
              label: const Text('New Category'),
            ),
          ),
          ...categories.map((category) {
            final isSelected = selectedCategoryIds.contains(category.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (_) => onCategoryToggled(category.id),
                avatar: CircleAvatar(backgroundColor: category.color),
                label: Text(category.name),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: category.color.withOpacity(0.3),
                  width: 1,
                ),
                selectedColor: category.color.withOpacity(0.2),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../cubit/search_cubit.dart';

typedef OnFieldFilterChanged = Function(FieldFilter? filter);

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.onNewTask,
    this.onFieldFilterChanged,
    this.onClearFilters,
    this.availableFilters = const [],
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onNewTask;
  final OnFieldFilterChanged? onFieldFilterChanged;
  final VoidCallback? onClearFilters;
  
  /// List of available field filters [fieldId, fieldName, options]
  final List<(String, String, List<String>)> availableFilters;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  final _selectedFieldFilters = <String, List<String>>{};
  bool _showFilterPanel = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  void _updateFieldFilter(String fieldId, String fieldName, List<String> values) {
    setState(() {
      if (values.isEmpty) {
        _selectedFieldFilters.remove(fieldId);
      } else {
        _selectedFieldFilters[fieldId] = values;
      }
    });
    
    if (values.isNotEmpty) {
      widget.onFieldFilterChanged?.call(
        FieldFilter(
          fieldId: fieldId,
          fieldName: fieldName,
          selectedValues: values,
        ),
      );
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFieldFilters.clear();
      _showFilterPanel = false;
    });
    widget.onClearFilters?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title, description...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              widget.onClear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _toggleFilterPanel,
                    tooltip: 'Add field filters',
                  ),
                  if (_selectedFieldFilters.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${_selectedFieldFilters.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              FloatingActionButton.extended(
                onPressed: widget.onNewTask,
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
              ),
            ],
          ),
        ),
        // Filter panel (when expanded)
        if (_showFilterPanel && widget.availableFilters.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withAlpha(200),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(50),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Field',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_selectedFieldFilters.isNotEmpty)
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (fieldId, fieldName, options) in widget.availableFilters)
                      _FilterChip(
                        fieldId: fieldId,
                        fieldName: fieldName,
                        options: options,
                        isSelected: _selectedFieldFilters.containsKey(fieldId),
                        selectedValues: _selectedFieldFilters[fieldId] ?? [],
                        onChanged: (values) => _updateFieldFilter(fieldId, fieldName, values),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A chip-based filter selector for a single field
class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.fieldId,
    required this.fieldName,
    required this.options,
    required this.isSelected,
    required this.selectedValues,
    required this.onChanged,
  });

  final String fieldId;
  final String fieldName;
  final List<String> options;
  final bool isSelected;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  late List<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List.from(widget.selectedValues);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by ${widget.fieldName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in widget.options)
                CheckboxListTile(
                  title: Text(option),
                  value: _localSelected.contains(option),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        if (!_localSelected.contains(option)) {
                          _localSelected.add(option);
                        }
                      } else {
                        _localSelected.remove(option);
                      }
                    });
                  },
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
              widget.onChanged(_localSelected);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(widget.fieldName),
      onPressed: _showFilterDialog,
      selected: widget.isSelected,
      onDeleted: widget.isSelected
          ? () {
              widget.onChanged([]);
            }
          : null,
      avatar: widget.isSelected
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${widget.selectedValues.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

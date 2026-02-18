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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF30363D), width: 1),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onChanged,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search tasks…',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF8B949E),
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              color: const Color(0xFF8B949E),
                              onPressed: () {
                                _controller.clear();
                                widget.onClear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button with badge
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedFieldFilters.isNotEmpty
                          ? const Color(0xFFBB86FC).withAlpha(25)
                          : const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedFieldFilters.isNotEmpty
                            ? const Color(0xFFBB86FC).withAlpha(80)
                            : const Color(0xFF30363D),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.filter_list,
                        size: 18,
                        color: _selectedFieldFilters.isNotEmpty
                            ? const Color(0xFFBB86FC)
                            : const Color(0xFF8B949E),
                      ),
                      onPressed: _toggleFilterPanel,
                      tooltip: 'Add field filters',
                    ),
                  ),
                  if (_selectedFieldFilters.isNotEmpty)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBB86FC),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_selectedFieldFilters.length}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // New Task pill button
              GestureDetector(
                onTap: widget.onNewTask,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBB86FC).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFBB86FC).withAlpha(100),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Color(0xFFBB86FC)),
                      SizedBox(width: 5),
                      Text(
                        'New Task',
                        style: TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filter panel (when expanded)
        if (_showFilterPanel && widget.availableFilters.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1C2128),
              border: Border(
                top: BorderSide(color: Color(0xFF30363D), width: 1),
                bottom: BorderSide(color: Color(0xFF30363D), width: 1),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFE6EDF3),
                        fontSize: 13,
                      ),
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

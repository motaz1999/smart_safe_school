import 'package:flutter/material.dart';

class AbsenceFilters extends StatefulWidget {
  final String? selectedClassId;
  final String? selectedSubjectId;
  final String searchQuery;
  final List<DropdownItem> classes;
  final List<DropdownItem> subjects;
  final Function(String? classId) onClassChanged;
  final Function(String? subjectId) onSubjectChanged;
  final Function(String query) onSearchChanged;
  final VoidCallback? onClearFilters;
  final VoidCallback? onExport;

  const AbsenceFilters({
    super.key,
    this.selectedClassId,
    this.selectedSubjectId,
    this.searchQuery = '',
    this.classes = const [],
    this.subjects = const [],
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onSearchChanged,
    this.onClearFilters,
    this.onExport,
  });

  @override
  State<AbsenceFilters> createState() => _AbsenceFiltersState();
}

class _AbsenceFiltersState extends State<AbsenceFilters> {
  late TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters & Search',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_hasActiveFilters()) ...[
                  Chip(
                    label: Text('${_getActiveFilterCount()} active'),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
            
            // Search bar (always visible)
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name, ID, class, or subject...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: widget.onSearchChanged,
            ),
            
            // Expandable filters section
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Filter dropdowns
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Class',
                      value: widget.selectedClassId,
                      items: widget.classes,
                      onChanged: widget.onClassChanged,
                      hint: 'All Classes',
                      icon: Icons.class_,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Subject',
                      value: widget.selectedSubjectId,
                      items: widget.subjects,
                      onChanged: widget.onSubjectChanged,
                      hint: 'All Subjects',
                      icon: Icons.book,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  if (_hasActiveFilters()) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onClearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  if (widget.onExport != null)
                    ElevatedButton.icon(
                      onPressed: widget.onExport,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
            
            // Quick filter chips (when collapsed)
            if (!_isExpanded && _hasActiveFilters()) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (widget.selectedClassId != null)
                    _buildFilterChip(
                      'Class: ${_getClassName(widget.selectedClassId!)}',
                      () => widget.onClassChanged(null),
                    ),
                  if (widget.selectedSubjectId != null)
                    _buildFilterChip(
                      'Subject: ${_getSubjectName(widget.selectedSubjectId!)}',
                      () => widget.onSubjectChanged(null),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownItem> items,
    required Function(String?) onChanged,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                hint,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item.value,
                  child: Text(item.label),
                )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 12,
      ),
    );
  }

  bool _hasActiveFilters() {
    return widget.selectedClassId != null || 
           widget.selectedSubjectId != null ||
           widget.searchQuery.isNotEmpty;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (widget.selectedClassId != null) count++;
    if (widget.selectedSubjectId != null) count++;
    if (widget.searchQuery.isNotEmpty) count++;
    return count;
  }

  String _getClassName(String classId) {
    final classItem = widget.classes.firstWhere(
      (item) => item.value == classId,
      orElse: () => DropdownItem(value: classId, label: 'Unknown'),
    );
    return classItem.label;
  }

  String _getSubjectName(String subjectId) {
    final subjectItem = widget.subjects.firstWhere(
      (item) => item.value == subjectId,
      orElse: () => DropdownItem(value: subjectId, label: 'Unknown'),
    );
    return subjectItem.label;
  }
}

class DropdownItem {
  final String value;
  final String label;

  const DropdownItem({
    required this.value,
    required this.label,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropdownItem &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => value.hashCode ^ label.hashCode;

  @override
  String toString() => 'DropdownItem(value: $value, label: $label)';
}
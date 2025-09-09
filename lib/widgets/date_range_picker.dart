import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;
  final String? label;

  const DateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
    this.label,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Quick date range buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickDateButton('Today', _getTodayRange()),
                _buildQuickDateButton('This Week', _getThisWeekRange()),
                _buildQuickDateButton('This Month', _getThisMonthRange()),
                _buildQuickDateButton('Last 7 Days', _getLast7DaysRange()),
                _buildQuickDateButton('Last 30 Days', _getLast30DaysRange()),
                _buildQuickDateButton('This Year', _getThisYearRange()),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Custom date range selection
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    context,
                    'Start Date',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    context,
                    'End Date',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canApplyDateRange() ? _applyDateRange : null,
                icon: const Icon(Icons.check),
                label: const Text('Apply Date Range'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Current selection display
            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, DateTimeRange range) {
    final isSelected = _startDate == range.start && _endDate == range.end;
    
    return OutlinedButton(
      onPressed: () => _selectQuickRange(range),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[400]!,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, date, onDateSelected),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : 'Select date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: date != null ? null : Colors.grey[500],
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectQuickRange(DateTimeRange range) {
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Date',
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  bool _canApplyDateRange() {
    return _startDate != null && 
           _endDate != null && 
           _startDate!.isBefore(_endDate!) || _startDate!.isAtSameMomentAs(_endDate!);
  }

  void _applyDateRange() {
    if (_canApplyDateRange()) {
      widget.onDateRangeSelected(_startDate!, _endDate!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Quick date range helpers
  DateTimeRange _getTodayRange() {
    final today = DateTime.now();
    return DateTimeRange(
      start: DateTime(today.year, today.month, today.day),
      end: DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return DateTimeRange(
      start: startOfMonth,
      end: DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59),
    );
  }

  DateTimeRange _getLast7DaysRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  DateTimeRange _getLast30DaysRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  DateTimeRange _getThisYearRange() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    return DateTimeRange(
      start: startOfYear,
      end: DateTime(endOfYear.year, endOfYear.month, endOfYear.day, 23, 59, 59),
    );
  }
}
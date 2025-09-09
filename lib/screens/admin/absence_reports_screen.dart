import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import '../../services/admin_service.dart';
import '../../services/export_service.dart';
import '../../models/absence_record.dart';
import '../../models/absence_summary_stats.dart';
import '../../widgets/absence_summary_card.dart';
import '../../widgets/absence_record_card.dart';
import '../../widgets/date_range_picker.dart';
import '../../widgets/absence_filters.dart';

class AbsenceReportsScreen extends StatefulWidget {
  const AbsenceReportsScreen({super.key});

  @override
  State<AbsenceReportsScreen> createState() => _AbsenceReportsScreenState();
}

class _AbsenceReportsScreenState extends State<AbsenceReportsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AdminService _adminService = AdminService();
  final ExportService _exportService = ExportService();
  
  // Data
  List<AbsenceRecord> _absenceRecords = [];
  AbsenceSummaryStats _summaryStats = AbsenceSummaryStats.empty();
  List<DropdownItem> _classes = [];
  List<DropdownItem> _subjects = [];
  
  // State
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedClassId;
  String? _selectedSubjectId;
  String _searchQuery = '';
  
  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreData = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load dropdown data
      await _loadDropdownData();
      
      // Load absence data
      await _loadAbsenceData(reset: true);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      // Load classes
      final classes = await _adminService.getClasses();
      _classes = classes.map((c) => DropdownItem(
        value: c.id,
        label: c.name,
      )).toList();

      // Load subjects
      final subjects = await _adminService.getSubjects();
      _subjects = subjects.map((s) => DropdownItem(
        value: s.id,
        label: s.name,
      )).toList();

    } catch (e) {
      // Error loading dropdown data: $e
    }
  }

  Future<void> _loadAbsenceData({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _hasMoreData = true;
      _absenceRecords.clear();
    }

    if (!_hasMoreData) return;

    try {
      // Load absence records
      final records = await _attendanceService.getAbsenceRecords(
        startDate: _startDate,
        endDate: _endDate,
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        context: context,
      );

      // Load summary stats (only on first load or filter change)
      if (reset || _currentPage == 0) {
        if (mounted) {
          _summaryStats = await _attendanceService.getAbsenceSummary(
            startDate: _startDate,
            endDate: _endDate,
            context: context,
          );
        }
      }

      setState(() {
        if (reset) {
          _absenceRecords = records;
        } else {
          _absenceRecords.addAll(records);
        }
        
        _hasMoreData = records.length == _pageSize;
        _currentPage++;
        _error = null;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadAbsenceData();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onDateRangeChanged(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadAbsenceData(reset: true);
  }

  void _onFiltersChanged() {
    _loadAbsenceData(reset: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedClassId = null;
      _selectedSubjectId = null;
      _searchQuery = '';
    });
    _onFiltersChanged();
  }

  void _exportData() {
    if (_absenceRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ExportDialog(
        records: _absenceRecords,
        summary: _summaryStats,
        exportService: _exportService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absence Reports'),
        actions: [
          IconButton(
            onPressed: () => _loadInitialData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Picker
                        DateRangePicker(
                          startDate: _startDate,
                          endDate: _endDate,
                          onDateRangeSelected: _onDateRangeChanged,
                          label: 'Select Date Range',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Summary Statistics
                        AbsenceSummaryCard(summary: _summaryStats),
                        
                        const SizedBox(height: 16),
                        
                        // Filters
                        AbsenceFilters(
                          selectedClassId: _selectedClassId,
                          selectedSubjectId: _selectedSubjectId,
                          searchQuery: _searchQuery,
                          classes: _classes,
                          subjects: _subjects,
                          onClassChanged: (classId) {
                            setState(() => _selectedClassId = classId);
                            _onFiltersChanged();
                          },
                          onSubjectChanged: (subjectId) {
                            setState(() => _selectedSubjectId = subjectId);
                            _onFiltersChanged();
                          },
                          onSearchChanged: (query) {
                            setState(() => _searchQuery = query);
                            // Debounce search
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_searchQuery == query) {
                                _onFiltersChanged();
                              }
                            });
                          },
                          onClearFilters: _clearFilters,
                          onExport: _exportData,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Results Header
                        _buildResultsHeader(),
                        
                        const SizedBox(height: 16),
                        
                        // Absence Records List
                        if (_absenceRecords.isEmpty)
                          _buildEmptyState()
                        else
                          _buildAbsenceRecordsList(),
                        
                        // Loading more indicator
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Absence Reports',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        Icon(
          Icons.list,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Absence Records',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_absenceRecords.length} records',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Absence Records Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your date range or filters to see more results.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceRecordsList() {
    return Column(
      children: _absenceRecords.map((record) => AbsenceRecordCard(
        record: record,
        showActions: true,
        onTap: () => _showRecordDetails(record),
      )).toList(),
    );
  }

  void _showRecordDetails(AbsenceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absence Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Student', record.studentName),
              _buildDetailRow('Student ID', record.studentNumber),
              _buildDetailRow('Class', record.className),
              _buildDetailRow('Subject', record.subjectName),
              _buildDetailRow('Teacher', record.teacherName),
              _buildDetailRow('Date', record.formattedDate),
              if (record.notes != null && record.notes!.isNotEmpty)
                _buildDetailRow('Notes', record.notes!),
              _buildDetailRow('Reason', record.displayReason),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  final List<AbsenceRecord> records;
  final AbsenceSummaryStats summary;
  final ExportService exportService;

  const _ExportDialog({
    required this.records,
    required this.summary,
    required this.exportService,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _selectedFormat = 'csv';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final formats = widget.exportService.getAvailableFormats();
    
    return AlertDialog(
      title: const Text('Export Absence Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export ${widget.records.length} absence records',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Select Format:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          ...formats.map((format) => RadioListTile<String>(
                title: Text(format.name),
                subtitle: Text(format.description),
                value: format.id,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() => _selectedFormat = value!);
                },
                dense: true,
              )),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The exported file will include all filtered records and summary statistics.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportData,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final exportData = widget.exportService.getExportData(
        widget.records,
        widget.summary,
        format: _selectedFormat,
      );
      
      // For now, we'll show the export data in a dialog
      // In a real implementation, you would trigger a download or save to file
      if (mounted) {
        Navigator.of(context).pop();
        _showExportResult(exportData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportResult(ExportData exportData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${exportData.fileName}'),
            Text('Type: ${exportData.mimeType}'),
            Text('Size: ${exportData.content.length} characters'),
            const SizedBox(height: 16),
            const Text(
              'In a production app, this would trigger a file download or save to device storage.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy content to clipboard or show preview
              _showContentPreview(exportData);
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    );
  }

  void _showContentPreview(ExportData exportData) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview: ${exportData.fileName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              exportData.content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
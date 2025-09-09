import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, Uri;
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/document_service.dart';

class TeacherDocumentsScreen extends StatefulWidget {
  const TeacherDocumentsScreen({super.key});

  @override
  State<TeacherDocumentsScreen> createState() => _TeacherDocumentsScreenState();
}

class _TeacherDocumentsScreenState extends State<TeacherDocumentsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final DocumentService _documentService = DocumentService();

  List<Document> _allDocuments = [];
  List<Document> _displayedDocuments = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterDocuments();
    });
  }

  void _filterDocuments() {
    if (_searchQuery.isEmpty) {
      _displayedDocuments = List.from(_allDocuments);
    } else {
      _displayedDocuments = _allDocuments
          .where((doc) => doc.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load documents sent by this teacher
      final documents = await _documentService.getSentDocuments(currentUser.id);

      setState(() {
        _allDocuments = documents;
        _displayedDocuments = List.from(documents);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadDocument(Document document) async {
    try {
      // Show loading indicator
      final snackBar = SnackBar(
        content: const Text('Downloading document...'),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // Get the download URL using the document service
      final url = await _documentService.downloadFile(document.filePath);
      print('Generated download URL: $url');

      // Use url_launcher to open the file
      await launchUrl(Uri.parse(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document opened in browser or downloaded')),
      );
    } catch (e) {
      print('Error downloading document: $e');
      String errorMessage = 'Failed to download document';
      if (e.toString().contains('Object not found') ||
          e.toString().contains('not_found')) {
        errorMessage =
            'Document file not found in storage. It may have been deleted or the file path is incorrect.';
      } else if (e.toString().contains('Bucket not found')) {
        errorMessage =
            'Document storage bucket not found. Please contact administrator.';
      } else {
        errorMessage = 'Failed to download document: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _deleteDocument(Document document) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this document?'),
            const SizedBox(height: 16),
            Text(
              'Document: ${document.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Recipients: ${document.recipientCount} students'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. The document will be removed from all recipients.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting document...'),
            ],
          ),
        ),
      );

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete the document
      await _documentService.deleteDocument(document.id, currentUser.id);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully')),
      );

      // Reload documents
      await _loadDocuments();
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    }
  }

  List<Document> _getRecentDocuments() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return _displayedDocuments
        .where((doc) => doc.createdAt.isAfter(thirtyDaysAgo))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSafeSchool'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Documents'),
            Tab(text: 'Recent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out the user
              Provider.of<AuthProvider>(context, listen: false).signOut();
              // Navigate back to login screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          if (!_isLoading && _error == null) _buildStatsCards(),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Document Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsList(_displayedDocuments),
                _buildDocumentsList(_getRecentDocuments()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalDocuments = _allDocuments.length;
    final totalRecipients = _allDocuments.fold<int>(
      0, (sum, doc) => sum + doc.recipientCount);
    final totalReads = _allDocuments.fold<int>(
      0, (sum, doc) => sum + doc.readCount);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Documents Sent',
              totalDocuments.toString(),
              Icons.description,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Recipients',
              totalRecipients.toString(),
              Icons.people,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Reads',
              totalReads.toString(),
              Icons.visibility,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(List<Document> documents) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No documents found'),
            const SizedBox(height: 8),
            const Text('Try changing your search criteria'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentCard(documents[index]);
        },
      ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Icon(
            _getIconForMimeType(document.mimeType),
            color: Colors.blue,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Sent: ${_formatDate(document.createdAt)}'),
            Text('Recipients: ${document.recipientCount} students'),
            Text('Read by: ${document.readCount} students'),
            if (document.fileName.isNotEmpty) 
              Text('File: ${document.fileName}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showDocumentDetails(document);
                break;
              case 'download':
                _downloadDocument(document);
                break;
              case 'delete':
                _deleteDocument(document);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () => _showDocumentDetails(document),
      ),
    );
  }

  IconData _getIconForMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audiotrack;
    } else if (mimeType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (mimeType == 'application/msword' ||
               mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return Icons.description;
    } else if (mimeType == 'application/vnd.ms-excel' ||
               mimeType == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return Icons.table_chart;
    } else if (mimeType == 'application/vnd.ms-powerpoint' ||
               mimeType == 'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
      return Icons.slideshow;
    } else if (mimeType.startsWith('text/')) {
      return Icons.text_snippet;
    } else {
      return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDocumentDetails(Document document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sent: ${_formatDate(document.createdAt)}'),
              const SizedBox(height: 8),
              Text('Recipients: ${document.recipientCount} students'),
              const SizedBox(height: 8),
              Text('Read by: ${document.readCount} students'),
              const SizedBox(height: 8),
              Text('Favorited by: ${document.favoriteCount} students'),
              if (document.fileName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('File: ${document.fileName}'),
              ],
              if (document.description != null && document.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Description: ${document.description}'),
              ],
              const SizedBox(height: 8),
              Text('File Type: ${document.mimeType}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadDocument(document);
              },
              child: const Text('Download'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDocument(document);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
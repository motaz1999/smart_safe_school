import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File, Directory;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, Uri;
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final DocumentService _documentService = DocumentService();

  List<StudentDocument> _allDocuments = [];
  List<StudentDocument> _displayedDocuments = [];
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
          .where((doc) => doc.documentTitle
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  Future<void> _searchDocuments() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final results = await _documentService.searchDocuments(
        studentId: currentUser.id,
        query: _searchQuery,
      );

      setState(() {
        _displayedDocuments = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search documents: $e')),
      );
    }
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Ensure the documents bucket exists
      try {
        await _documentService.ensureDocumentsBucketExists();
        await _documentService.setupBucketPolicies();
        print('Documents bucket verified and policies set up');
      } catch (bucketError) {
        print('Warning: Could not ensure documents bucket exists: $bucketError');
        // Don't fail the entire document loading process if bucket creation fails
        // The user might still be able to view document metadata even if they can't download files
      }

      // Run bucket diagnostic
      try {
        print('🔍 Running bucket diagnostic in document screen...');
        await _documentService.diagnoseBucketStatus();
      } catch (diagnosticError) {
        print('❌ Bucket diagnostic in document screen failed: $diagnosticError');
      }
      
      // Run document paths diagnostic
      try {
        print('🔍 Running document paths diagnostic...');
        await _documentService.diagnoseDocumentPaths();
      } catch (diagnosticError) {
        print('❌ Document paths diagnostic failed: $diagnosticError');
      }
      
      // Print all document paths for debugging
      try {
        print('🔍 Printing all document paths...');
        await _documentService.printAllDocumentPaths();
      } catch (error) {
        print('❌ Printing all document paths failed: $error');
      }

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load documents from the document service
      final documents =
          await _documentService.getReceivedDocumentsFiltered(currentUser.id);

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

  Future<void> _downloadDocument(StudentDocument document) async {
    try {
      // Show loading indicator
      final snackBar = SnackBar(
        content: const Text('Downloading document...'),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // Log the document path for debugging
      print('Attempting to download document with path: ${document.filePath}');

      // Get the download URL using the document service
      final url = await _documentService.downloadFile(document.filePath);
      print('Generated download URL: $url');

      // Use url_launcher to open the file on all platforms
      await launchUrl(Uri.parse(url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document opened in browser or downloaded')),
      );
    } catch (e) {
      print('Error downloading document: $e');
      // Show error message
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

  Future<void> _toggleFavorite(StudentDocument document) async {
    try {
      await _documentService.toggleFavorite(document.documentId, document.studentId);
      
      // Update the document in the list
      final index = _allDocuments.indexWhere((d) => d.id == document.id);
      if (index != -1) {
        setState(() {
          _allDocuments[index] = StudentDocument(
            id: _allDocuments[index].id,
            createdAt: _allDocuments[index].createdAt,
            updatedAt: _allDocuments[index].updatedAt,
            documentId: _allDocuments[index].documentId,
            studentId: _allDocuments[index].studentId,
            isRead: _allDocuments[index].isRead,
            isFavorite: !_allDocuments[index].isFavorite,
            documentTitle: _allDocuments[index].documentTitle,
            senderName: _allDocuments[index].senderName,
            filePath: _allDocuments[index].filePath,
            fileName: _allDocuments[index].fileName,
            fileSize: _allDocuments[index].fileSize,
            description: _allDocuments[index].description,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle favorite: $e')),
      );
    }
  }


  List<StudentDocument> _getFavoriteDocuments() {
    return _displayedDocuments.where((doc) => doc.isFavorite).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Favorites'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsList(_displayedDocuments),
                _buildDocumentsList(_getFavoriteDocuments()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(List<StudentDocument> documents) {
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
            const Text('Try changing your search or filter criteria'),
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

  Widget _buildDocumentCard(StudentDocument document) {
    final isUnread = !document.isRead;
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor:
              isUnread ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
          child: Icon(
            isUnread ? _getIconForMimeType(document.mimeType) : Icons.check,
            color: isUnread ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(
          document.documentTitle,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${document.senderName}'),
            Text('Received: ${_formatDate(document.createdAt)}'),
            if (document.fileName.isNotEmpty) Text('File: ${document.fileName}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document.isFavorite)
              const Icon(Icons.star, color: Colors.orange, size: 20),
            IconButton(
              icon: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
                color: document.isFavorite ? Colors.orange : null,
              ),
              onPressed: () => _toggleFavorite(document),
            ),
          ],
        ),
        onTap: () {
          _showDocumentDetails(document);
        },
      ),
    );
  }

  IconData _getIconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.description;
    
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

  void _showDocumentDetails(StudentDocument document) async {
    // Mark document as read
    if (!document.isRead) {
      try {
        await _documentService.markAsRead(document.documentId, document.studentId);
        
        // Update the document in the list
        final index = _allDocuments.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          setState(() {
            _allDocuments[index] = StudentDocument(
              id: _allDocuments[index].id,
              createdAt: _allDocuments[index].createdAt,
              updatedAt: _allDocuments[index].updatedAt,
              documentId: _allDocuments[index].documentId,
              studentId: _allDocuments[index].studentId,
              isRead: true,
              isFavorite: _allDocuments[index].isFavorite,
              documentTitle: _allDocuments[index].documentTitle,
              senderName: _allDocuments[index].senderName,
              filePath: _allDocuments[index].filePath,
              fileName: _allDocuments[index].fileName,
              fileSize: _allDocuments[index].fileSize,
              description: _allDocuments[index].description,
            );
          });
        }
      } catch (e) {
        // Handle error silently or show a message
        debugPrint('Failed to mark document as read: $e');
      }
    }

    // Show document details dialog
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document.documentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From: ${document.senderName}'),
              const SizedBox(height: 8),
              Text('Received: ${_formatDate(document.createdAt)}'),
              if (document.fileName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('File: ${document.fileName}'),
              ],
              if (document.description != null && document.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Description: ${document.description}'),
              ],
              if (document.mimeType != null) ...[
                const SizedBox(height: 8),
                Text('File Type: ${document.mimeType}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadDocument(document);
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

}
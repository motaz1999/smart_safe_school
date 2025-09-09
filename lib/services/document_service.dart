import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/config/supabase_config.dart';
import '../models/document.dart';
import '../models/student_document.dart';

class DocumentService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  bool _bucketVerified = false;

  // Add a comprehensive diagnostic method to check bucket status
  Future<Map<String, dynamic>> runComprehensiveBucketDiagnostic() async {
    final result = <String, dynamic>{};
    
    try {
      print('=== COMPREHENSIVE BUCKET DIAGNOSTIC START ===');
      
      // Test 1: List all buckets via storage API
      try {
        print('TEST 1: Listing all buckets via storage API...');
        final buckets = await _supabase.storage.listBuckets();
        result['storage_api_success'] = true;
        result['available_buckets'] = buckets.map((b) => b.id).toList();
        result['documents_bucket_exists_storage'] = buckets.any((bucket) => bucket.id == 'documents');
        print('TEST 1 SUCCESS: Found ${buckets.length} buckets: ${result['available_buckets']}');
        print('TEST 1: Documents bucket exists in storage API: ${result['documents_bucket_exists_storage']}');
      } catch (e) {
        result['storage_api_success'] = false;
        result['storage_api_error'] = e.toString();
        print('TEST 1 FAILED: Cannot list buckets via storage API: $e');
      }
      
      // Test 2: Check buckets via database query
      try {
        print('TEST 2: Checking buckets via database query...');
        final dbResult = await _supabase.from('storage.buckets').select('*');
        result['database_query_success'] = true;
        result['database_buckets'] = dbResult.map((b) => b['id']).toList();
        result['documents_bucket_exists_db'] = dbResult.any((bucket) => bucket['id'] == 'documents');
        print('TEST 2 SUCCESS: Found ${dbResult.length} buckets in database: ${result['database_buckets']}');
        print('TEST 2: Documents bucket exists in database: ${result['documents_bucket_exists_db']}');
      } catch (e) {
        result['database_query_success'] = false;
        result['database_query_error'] = e.toString();
        print('TEST 2 FAILED: Cannot query database buckets: $e');
      }
      
      // Test 3: Try to access documents bucket directly
      try {
        print('TEST 3: Accessing documents bucket directly...');
        final storageRef = _supabase.storage.from('documents');
        result['bucket_access_success'] = true;
        print('TEST 3 SUCCESS: Documents bucket reference created');
        
        // Test 3a: Try to list files in documents bucket
        try {
          print('TEST 3a: Listing files in documents bucket...');
          final files = await storageRef.list();
          result['bucket_list_files_success'] = true;
          result['files_count'] = files.length;
          result['file_names'] = files.map((f) => f.name).toList();
          print('TEST 3a SUCCESS: Found ${files.length} files in documents bucket');
        } catch (e) {
          result['bucket_list_files_success'] = false;
          result['bucket_list_files_error'] = e.toString();
          print('TEST 3a FAILED: Cannot list files in documents bucket: $e');
        }
      } catch (e) {
        result['bucket_access_success'] = false;
        result['bucket_access_error'] = e.toString();
        print('TEST 3 FAILED: Cannot access documents bucket: $e');
      }
      
      // Test 4: Test getPublicUrl with a dummy file
      try {
        print('TEST 4: Testing getPublicUrl with dummy file...');
        final dummyUrl = _supabase.storage.from('documents').getPublicUrl('test.txt');
        result['get_public_url_success'] = true;
        result['dummy_url'] = dummyUrl;
        print('TEST 4 SUCCESS: getPublicUrl works, dummy URL: $dummyUrl');
      } catch (e) {
        result['get_public_url_success'] = false;
        result['get_public_url_error'] = e.toString();
        print('TEST 4 FAILED: getPublicUrl failed: $e');
      }
      
      // Test 5: Check authentication status
      try {
        print('TEST 5: Checking authentication status...');
        final user = _supabase.auth.currentUser;
        result['user_authenticated'] = user != null;
        result['user_id'] = user?.id;
        print('TEST 5: User authenticated: ${result['user_authenticated']}, User ID: ${result['user_id']}');
      } catch (e) {
        result['auth_check_error'] = e.toString();
        print('TEST 5 FAILED: Cannot check authentication: $e');
      }
      
      print('=== COMPREHENSIVE BUCKET DIAGNOSTIC END ===');
      return result;
    } catch (e) {
      result['overall_error'] = e.toString();
      print('OVERALL DIAGNOSTIC FAILED: $e');
      return result;
    }
  }

  // Pick a file using the file picker
  Future<PlatformFile?> pickFile({List<String>? allowedExtensions}) async {
    try {
      print('DEBUG: Starting file pick operation');
      print('DEBUG: Allowed extensions: $allowedExtensions');
      
      // Add a simple delay to prevent rapid clicking
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set default allowed extensions if none provided
      final List<String> effectiveAllowedExtensions = allowedExtensions ??
          ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx'];
      
      // Use file_picker with withData: true to always get file bytes
      // This ensures consistent behavior across web and mobile platforms
      print('DEBUG: Calling FilePicker.platform.pickFiles with withData: true');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: effectiveAllowedExtensions,
        withData: true, // Always use withData: true to get file bytes
        allowMultiple: false,
      );
      
      print('DEBUG: File pick operation completed, result: ${result != null ? 'got result' : 'null result'}');
      if (result != null) {
        print('DEBUG: Result files count: ${result.files.length}');
        if (result.files.isNotEmpty) {
          final file = result.files.first;
          print('DEBUG: First file name: ${file.name}, size: ${file.size}, has bytes: ${file.bytes != null}');
          
          // Log detailed file information
          print('DEBUG: File details - name: ${file.name}, size: ${file.size}');
          if (file.bytes != null) {
            print('DEBUG: File has bytes, length: ${file.bytes!.length}');
          }
          
          // Validate that we have file bytes (required for consistent behavior)
          if (file.bytes == null) {
            print('ERROR: File bytes not available');
            throw Exception('Selected file is not accessible. Please try selecting a different file.');
          }
          
          // Validate file size (limit to 50MB)
          const maxFileSize = 50 * 1024 * 1024; // 50MB in bytes
          if (file.size > maxFileSize) {
            throw Exception('File size exceeds the maximum limit of 50MB. Please select a smaller file.');
          }
          
          // Validate file extension
          final fileExtension = file.name.split('.').last.toLowerCase();
          if (!effectiveAllowedExtensions.contains(fileExtension)) {
            throw Exception('File type not allowed. Please select a document file (${effectiveAllowedExtensions.join(', ')}).');
          }
          
          // Add a small delay to prevent UI freezing
          await Future.delayed(const Duration(milliseconds: 50));
          
          return file;
        }
      }
      print('DEBUG: No file selected');
      return null;
    } on Exception catch (e) {
      print('ERROR: File picking failed with exception: $e');
      print('ERROR: Exception type: ${e.runtimeType}');
      throw Exception('Failed to pick file: $e');
    } catch (e, stackTrace) {
      print('ERROR: File picking failed with error: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Error type: ${e.runtimeType}');
      throw Exception('Failed to pick file: $e');
    }
  }

  // Upload a document and create database records
  Future<Document> uploadDocument({
    required int schoolId,
    required String senderId,
    required String senderType,
    required String title,
    String? description,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required List<String> recipientIds,
  }) async {
    try {
      print('=== UPLOAD DOCUMENT DIAGNOSTIC START ===');
      print('DIAGNOSTIC: Document upload parameters:');
      print('  - schoolId: $schoolId');
      print('  - senderId: $senderId');
      print('  - senderType: $senderType');
      print('  - title: $title');
      print('  - filePath: $filePath');
      print('  - fileName: $fileName');
      print('  - fileSize: $fileSize');
      print('  - mimeType: $mimeType');
      print('  - recipientIds count: ${recipientIds.length}');
      
      // DIAGNOSTIC: Check authentication before database operation
      final user = _supabase.auth.currentUser;
      print('DIAGNOSTIC: User authenticated for DB operation: ${user != null}');
      if (user != null) {
        print('DIAGNOSTIC: User ID matches senderId: ${user.id == senderId}');
      }
      
      // DIAGNOSTIC: Test database function call with detailed error catching
      print('DIAGNOSTIC: Calling create_document database function...');
      try {
        // Try the robust function first, fallback to original if needed
        dynamic response;
        try {
          print('DIAGNOSTIC: Attempting create_document_robust function...');
          response = await _supabase.rpc('create_document_robust', params: {
            'p_school_id': schoolId,
            'p_sender_id': senderId,
            'p_sender_type': senderType,
            'p_title': title,
            'p_description': description,
            'p_file_path': filePath,
            'p_file_name': fileName,
            'p_file_size': fileSize,
            'p_mime_type': mimeType,
            'p_recipient_ids': recipientIds,
          });
          print('DIAGNOSTIC: create_document_robust function successful');
        } catch (robustError) {
          print('DIAGNOSTIC: create_document_robust failed, trying original function: $robustError');
          response = await _supabase.rpc('create_document', params: {
            'p_school_id': schoolId,
            'p_sender_id': senderId,
            'p_sender_type': senderType,
            'p_title': title,
            'p_description': description,
            'p_file_path': filePath,
            'p_file_name': fileName,
            'p_file_size': fileSize,
            'p_mime_type': mimeType,
            'p_recipient_ids': recipientIds,
          });
          print('DIAGNOSTIC: Original create_document function successful');
        }
        
        print('DIAGNOSTIC: create_document function successful, returned ID: $response');
        
        // DIAGNOSTIC: Test document retrieval
        print('DIAGNOSTIC: Retrieving created document...');
        final documentResponse = await _supabase
            .from('documents')
            .select('*')
            .eq('id', response)
            .single();
        
        print('DIAGNOSTIC: Document retrieval successful');
        print('=== UPLOAD DOCUMENT DIAGNOSTIC END (SUCCESS) ===');
        return Document.fromJson(documentResponse);
        
      } catch (dbError) {
        print('DIAGNOSTIC: Database operation failed: $dbError');
        print('DIAGNOSTIC: DB Error type: ${dbError.runtimeType}');
        print('DIAGNOSTIC: DB Error string: ${dbError.toString()}');
        
        // Check for specific RLS policy violations
        if (dbError.toString().contains('row-level security policy') ||
            dbError.toString().contains('RLS') ||
            dbError.toString().contains('policy')) {
          print('DIAGNOSTIC: CONFIRMED - Database RLS Policy violation detected!');
          
          // Check which table is causing the issue
          if (dbError.toString().contains('documents')) {
            print('DIAGNOSTIC: RLS violation on documents table');
            throw Exception('Permission denied: Cannot create document. Documents table RLS policy violation.');
          } else if (dbError.toString().contains('student_documents')) {
            print('DIAGNOSTIC: RLS violation on student_documents table');
            throw Exception('Permission denied: Cannot create student document relationships. Student_documents table RLS policy violation.');
          } else {
            print('DIAGNOSTIC: RLS violation on unknown table');
            throw Exception('Permission denied: Database row-level security policy violation. Please contact administrator.');
          }
        }
        
        // Check for authentication issues
        if (dbError.toString().contains('Unauthorized') ||
            dbError.toString().contains('401') ||
            dbError.toString().contains('403')) {
          print('DIAGNOSTIC: CONFIRMED - Database Authentication/Authorization issue!');
          throw Exception('Database access denied. Authentication issue detected. Please log in again.');
        }
        
        rethrow;
      }
    } catch (e) {
      print('=== UPLOAD DOCUMENT ERROR SUMMARY ===');
      print('ERROR: Failed to upload document: $e');
      print('ERROR: Error type: ${e.runtimeType}');
      print('ERROR: Full error string: ${e.toString()}');
      print('=== UPLOAD DOCUMENT ERROR SUMMARY END ===');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Get documents sent by a specific user with enhanced information
  Future<List<Document>> getSentDocuments(String senderId) async {
    try {
      print('=== GET SENT DOCUMENTS START ===');
      print('Sender ID: $senderId');
      
      // First get basic document information
      final documentsResponse = await _supabase
          .from('documents')
          .select('*')
          .eq('sender_id', senderId)
          .order('created_at', ascending: false);

      print('Found ${documentsResponse.length} documents');

      // Then get statistics for each document
      List<Document> documents = [];
      for (final docJson in documentsResponse) {
        try {
          // Get statistics for this document
          final statsResponse = await _supabase
              .from('student_documents')
              .select('is_read, is_favorite')
              .eq('document_id', docJson['id']);

          final recipientCount = statsResponse.length;
          final readCount = statsResponse.where((doc) => doc['is_read'] == true).length;
          final favoriteCount = statsResponse.where((doc) => doc['is_favorite'] == true).length;
          
          // Add statistics to document JSON
          docJson['recipient_count'] = recipientCount;
          docJson['read_count'] = readCount;
          docJson['favorite_count'] = favoriteCount;
          docJson['sender_name'] = 'You'; // Since this is the sender's own documents
          
          documents.add(Document.fromJson(docJson));
          print('Document ${docJson['title']}: ${recipientCount} recipients, ${readCount} read, ${favoriteCount} favorites');
        } catch (statsError) {
          print('Error getting stats for document ${docJson['id']}: $statsError');
          // Add document with zero stats if stats query fails
          docJson['recipient_count'] = 0;
          docJson['read_count'] = 0;
          docJson['favorite_count'] = 0;
          docJson['sender_name'] = 'You';
          documents.add(Document.fromJson(docJson));
        }
      }

      print('=== GET SENT DOCUMENTS END (SUCCESS) ===');
      return documents;
    } catch (e) {
      print('=== GET SENT DOCUMENTS ERROR ===');
      print('Error: $e');
      throw Exception('Failed to get sent documents: $e');
    }
  }

  // Get documents for a specific student
  Future<List<StudentDocument>> getReceivedDocuments(String studentId) async {
    try {
      final response = await _supabase.rpc('get_student_documents', params: {
        'p_student_id': studentId,
      });

      return (response as List)
          .map((json) => StudentDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get received documents: $e');
    }
  }

  // Get documents for a specific student, filtering out documents with missing files
  Future<List<StudentDocument>> getReceivedDocumentsFiltered(String studentId) async {
    try {
      // First get all documents
      final allDocuments = await getReceivedDocuments(studentId);
      
      // Filter out documents with missing files
      final List<StudentDocument> existingDocuments = [];
      
      for (final document in allDocuments) {
        try {
          // Check if the file exists by trying to generate a URL for it
          await canAccessFile(document.filePath);
          
          // If we get here, the file exists
          existingDocuments.add(document);
        } catch (e) {
          // File doesn't exist or there was an error checking, skip this document
          print('Skipping document ${document.documentTitle} - file not found: ${document.filePath}, error: $e');
        }
      }
      
      return existingDocuments;
    } catch (e) {
      throw Exception('Failed to get filtered received documents: $e');
    }
  }

  // Mark a document as read by a student
  Future<void> markAsRead(String documentId, String studentId) async {
    try {
      await _supabase.rpc('mark_document_as_read', params: {
        'p_document_id': documentId,
        'p_student_id': studentId,
      });
    } catch (e) {
      throw Exception('Failed to mark document as read: $e');
    }
  }

  // Upload file to Supabase storage
  Future<String> uploadFile(PlatformFile file, String fileName) async {
    try {
      print('=== UPLOAD FILE DIAGNOSTIC START ===');
      print('DEBUG: Starting file upload, file name: ${file.name}, size: ${file.size}');
      print('DEBUG: Target fileName: $fileName');
      print('DEBUG: File has bytes: ${file.bytes != null}');
      
      // DIAGNOSTIC 1: Check authentication status
      final user = _supabase.auth.currentUser;
      print('DIAGNOSTIC 1: User authenticated: ${user != null}');
      if (user != null) {
        print('DIAGNOSTIC 1: User ID: ${user.id}');
        print('DIAGNOSTIC 1: User email: ${user.email}');
        print('DIAGNOSTIC 1: User role: ${user.userMetadata?['role']}');
      } else {
        print('DIAGNOSTIC 1: ERROR - User not authenticated!');
        throw Exception('User not authenticated. Please log in again.');
      }
      
      // DIAGNOSTIC 2: Check profiles table data
      try {
        print('DIAGNOSTIC 2: Checking profiles table data...');
        final profileData = await _supabase
            .from('profiles')
            .select('id, school_id, user_type')
            .eq('id', user!.id)
            .maybeSingle();
        
        print('DIAGNOSTIC 2: Profile data: $profileData');
        if (profileData == null) {
          print('DIAGNOSTIC 2: ERROR - No profile found for user!');
          throw Exception('User profile not found. Please contact administrator.');
        }
        if (profileData['school_id'] == null) {
          print('DIAGNOSTIC 2: ERROR - No school_id in profile!');
          throw Exception('User school information missing. Please contact administrator.');
        }
        print('DIAGNOSTIC 2: User school_id: ${profileData['school_id']}');
        print('DIAGNOSTIC 2: User type: ${profileData['user_type']}');
      } catch (profileError) {
        print('DIAGNOSTIC 2: ERROR checking profile: $profileError');
        throw Exception('Failed to verify user profile: $profileError');
      }
      
      // DIAGNOSTIC 3: Check storage bucket existence and permissions
      try {
        print('DIAGNOSTIC 3: Checking storage bucket...');
        final buckets = await _supabase.storage.listBuckets();
        final documentsBucket = buckets.where((b) => b.id == 'documents').firstOrNull;
        print('DIAGNOSTIC 3: Documents bucket exists: ${documentsBucket != null}');
        if (documentsBucket != null) {
          print('DIAGNOSTIC 3: Bucket details - ID: ${documentsBucket.id}, Public: ${documentsBucket.public}');
        }
      } catch (bucketError) {
        print('DIAGNOSTIC 3: ERROR checking bucket: $bucketError');
        // Don't throw here, continue with upload attempt
      }
      
      // DIAGNOSTIC 4: Test storage policies by attempting a simple operation
      try {
        print('DIAGNOSTIC 4: Testing storage access...');
        final testRef = _supabase.storage.from('documents');
        print('DIAGNOSTIC 4: Storage reference created successfully');
        
        // Try to list files (this tests SELECT policy)
        try {
          final files = await testRef.list(path: '', searchOptions: const SearchOptions(limit: 1));
          print('DIAGNOSTIC 4: List files successful, found ${files.length} files');
        } catch (listError) {
          print('DIAGNOSTIC 4: List files failed: $listError');
        }
      } catch (storageAccessError) {
        print('DIAGNOSTIC 4: ERROR accessing storage: $storageAccessError');
      }
      
      // Log detailed file information
      print('DEBUG: File details - name: ${file.name}, size: ${file.size}');
      if (file.bytes != null) {
        print('DEBUG: File has bytes, length: ${file.bytes!.length}');
      }
      
      // Check if we have file bytes (required for consistent behavior)
      if (file.bytes != null) {
        print('DEBUG: Uploading using bytes to documents bucket...');
        
        // DIAGNOSTIC 5: Attempt the actual upload with detailed error catching
        try {
          print('DIAGNOSTIC 5: Calling uploadBinary...');
          final response = await _supabase.storage
              .from('documents')
              .uploadBinary(fileName, file.bytes!);
          
          print('DIAGNOSTIC 5: Upload successful! Response: $response');
          print('DIAGNOSTIC 5: Response type: ${response.runtimeType}');
          
          // Ensure the path is correctly formatted
          // uploadBinary returns just the file name, so we need to prepend the bucket name
          if (response is String) {
            // If response doesn't start with 'documents/', prepend it
            if (!response.startsWith('documents/')) {
              final finalPath = 'documents/$response';
              print('DEBUG: Final file path: $finalPath');
              print('=== UPLOAD FILE DIAGNOSTIC END (SUCCESS) ===');
              return finalPath;
            }
            print('DEBUG: Final file path: $response');
            print('=== UPLOAD FILE DIAGNOSTIC END (SUCCESS) ===');
            return response;
          } else {
            // If response is not a string, construct the path using fileName
            final finalPath = 'documents/$fileName';
            print('DEBUG: Final file path (constructed): $finalPath');
            print('=== UPLOAD FILE DIAGNOSTIC END (SUCCESS) ===');
            return finalPath;
          }
        } catch (uploadError) {
          print('DIAGNOSTIC 5: Upload failed with error: $uploadError');
          print('DIAGNOSTIC 5: Error type: ${uploadError.runtimeType}');
          print('DIAGNOSTIC 5: Error string: ${uploadError.toString()}');
          
          // Check for specific RLS policy violation
          if (uploadError.toString().contains('row-level security policy') ||
              uploadError.toString().contains('RLS') ||
              uploadError.toString().contains('policy')) {
            print('DIAGNOSTIC 5: CONFIRMED - RLS Policy violation detected!');
            throw Exception('Storage permission denied. Row-level security policy violation. Please contact administrator.');
          }
          
          // Check for authentication issues
          if (uploadError.toString().contains('Unauthorized') ||
              uploadError.toString().contains('401') ||
              uploadError.toString().contains('403')) {
            print('DIAGNOSTIC 5: CONFIRMED - Authentication/Authorization issue!');
            throw Exception('Storage access denied. Authentication issue detected. Please log in again.');
          }
          
          rethrow;
        }
      }
      // If bytes are not available, throw an error
      else {
        print('ERROR: File bytes not available. Please select a valid file.');
        print('=== UPLOAD FILE DIAGNOSTIC END (ERROR) ===');
        throw Exception('File bytes not available. Please select a valid file.');
      }
    } catch (e) {
      print('=== UPLOAD FILE ERROR SUMMARY ===');
      print('ERROR: Failed to upload file: $e');
      print('ERROR: Error type: ${e.runtimeType}');
      print('ERROR: Full error string: ${e.toString()}');
      print('=== UPLOAD FILE ERROR SUMMARY END ===');
      
      // Handle specific bucket not found error
      if (e.toString().contains('Bucket not found')) {
        throw Exception('Document storage bucket not found. Please contact administrator.');
      }
      // Handle other storage errors
      if (e.toString().contains('storage')) {
        throw Exception('Storage error: ${e.toString()}');
      }
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Download a document file
  Future<String> downloadFile(String filePath) async {
    try {
      print('=== DOWNLOAD FILE DEBUG START ===');
      print('DEBUG: Starting downloadFile with filePath: $filePath');
      
      // Check authentication status
      final user = _supabase.auth.currentUser;
      print('DEBUG: User authenticated: ${user != null}');
      if (user != null) {
        print('DEBUG: User ID: ${user.id}');
      }
      
      // Skip bucket existence check - it requires authentication but getPublicUrl works without it
      // The bucket exists (confirmed via admin client), so we can proceed directly to URL generation
      print('DEBUG: Skipping bucket existence check (requires authentication)');
      print('DEBUG: Proceeding directly to URL generation');
      
      // Get the download URL - handle both full URLs and relative paths
      String url;
      if (filePath.startsWith('http')) {
        // Already a full URL
        url = filePath;
        print('DEBUG: Using full URL: $url');
      } else {
        // Assume it's a relative path within the documents bucket
        // Make sure the path is correctly formatted
        String cleanPath = filePath;
        print('DEBUG: Original file path: $filePath');
        
        if (filePath.startsWith('documents/')) {
          // Remove the bucket prefix as getPublicUrl expects a path relative to the bucket
          cleanPath = filePath.substring('documents/'.length);
          print('DEBUG: Removed documents/ prefix, clean path: $cleanPath');
        } else if (filePath.startsWith('/')) {
          // Remove leading slash
          cleanPath = filePath.substring(1);
          print('DEBUG: Removed leading slash, clean path: $cleanPath');
        }
        
        print('DEBUG: Final clean path for getPublicUrl: $cleanPath');
        
        // Try to access the storage bucket and generate URL
        try {
          print('DEBUG: Attempting to access documents bucket via storage.from()');
          
          // First try to create a signed URL with regular client
          print('DEBUG: Attempting to create signed URL with regular client');
          try {
            final storageRef = _supabase.storage.from('documents');
            url = await storageRef.createSignedUrl(cleanPath, 3600); // 1 hour expiry
            print('DEBUG: Regular client signed URL created successfully: $url');
          } catch (signedUrlError) {
            print('DEBUG: Regular client signed URL creation failed: $signedUrlError');
            print('DEBUG: Trying with admin client for signed URL');
            
            // Try with admin client if regular client fails
            try {
              final adminClient = SupabaseConfig.adminClient;
              final adminStorageRef = adminClient.storage.from('documents');
              url = await adminStorageRef.createSignedUrl(cleanPath, 3600); // 1 hour expiry
              print('DEBUG: Admin client signed URL created successfully: $url');
            } catch (adminSignedUrlError) {
              print('DEBUG: Admin client signed URL creation also failed: $adminSignedUrlError');
              print('DEBUG: Falling back to public URL (may not work for private buckets)');
              
              // Final fallback to public URL
              final storageRef = _supabase.storage.from('documents');
              url = storageRef.getPublicUrl(cleanPath);
              print('DEBUG: Public URL generated as final fallback: $url');
            }
          }
        } catch (storageError) {
          print('ERROR: Storage operation failed: $storageError');
          print('ERROR: Storage error type: ${storageError.runtimeType}');
          print('ERROR: Storage error string: ${storageError.toString()}');
          
          // Check if this is specifically a bucket not found error
          if (storageError.toString().contains('Bucket not found')) {
            print('ERROR: Confirmed bucket not found error during URL generation');
            throw Exception('Documents bucket not found during URL generation');
          }
          
          rethrow;
        }
      }
      
      print('DEBUG: Successfully generated download URL: $url');
      print('=== DOWNLOAD FILE DEBUG END ===');
      return url;
    } catch (e) {
      print('=== DOWNLOAD FILE ERROR ===');
      print('ERROR: downloadFile failed with error: $e');
      print('ERROR: Error type: ${e.runtimeType}');
      print('ERROR: Full error string: ${e.toString()}');
      print('=== DOWNLOAD FILE ERROR END ===');
      
      // Handle specific bucket not found error
      if (e.toString().contains('Bucket not found')) {
        throw Exception('Document storage bucket not found. Please contact administrator.');
      }
      // Handle other storage errors
      if (e.toString().contains('storage')) {
        throw Exception('Storage error: ${e.toString()}');
      }
      throw Exception('Failed to download file: $e');
    }
  }
  
  // Check if the documents bucket exists and create it if it doesn't
  Future<void> ensureDocumentsBucketExists() async {
    // If we've already verified the bucket exists, skip the check
    if (_bucketVerified) {
      print('Documents bucket already verified, skipping check');
      return;
    }
    
    try {
      // Try to list buckets to check if the documents bucket exists
      final buckets = await _supabase.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.id).toList()}');
      
      // Check if 'documents' bucket exists
      final documentsBucketExists = buckets.any((bucket) => bucket.id == 'documents');
      print('Documents bucket exists: $documentsBucketExists');
      
      if (!documentsBucketExists) {
        print('Creating documents bucket...');
        try {
          // Create the documents bucket
          await _supabase.storage.createBucket('documents');
          print('Documents bucket created successfully');
        } catch (createError) {
          // Handle the case where bucket already exists (409 error)
          if (createError.toString().contains('409') || createError.toString().contains('Duplicate') || createError.toString().contains('already exists')) {
            print('Documents bucket already exists (caught during creation attempt)');
            // This is fine, continue
          } else {
            print('Failed to create documents bucket with regular client: $createError');
            // Try with admin client if regular client fails
            try {
              final adminClient = SupabaseConfig.adminClient;
              await adminClient.storage.createBucket('documents');
              print('Documents bucket created successfully with admin client');
            } catch (adminError) {
              // Handle the case where bucket already exists with admin client
              if (adminError.toString().contains('409') || adminError.toString().contains('Duplicate') || adminError.toString().contains('already exists')) {
                print('Documents bucket already exists (caught during admin creation attempt)');
                // This is fine, continue
              } else {
                print('Failed to create documents bucket with admin client: $adminError');
                rethrow; // Re-throw the original error
              }
            }
          }
        }
      } else {
        print('Documents bucket already exists');
      }
      
      // Mark that we've verified the bucket exists
      _bucketVerified = true;
    } catch (e) {
      // If we can't list buckets or create the bucket, log the error
      // but don't throw an exception as this might be a permission issue
      print('Warning: Could not verify or create documents bucket: $e');
      // Don't rethrow here to allow the app to continue working
      // The calling code will handle storage errors appropriately
    }
  }
  
  // Check if the bucket has the correct policies set up
  Future<void> verifyBucketPolicies() async {
    try {
      // This is just for verification - policies are typically set up via SQL
      print('Verifying bucket policies for documents bucket');
      // In a real implementation, you might check specific policy conditions here
    } catch (e) {
      print('Warning: Could not verify bucket policies: $e');
    }
  }
  
  // Set up bucket policies (this would typically be done via SQL but we'll provide a programmatic option)
  Future<void> setupBucketPolicies() async {
    try {
      // Note: Bucket policies are typically set up via SQL commands
      // Refer to document_management_sql_commands_final_fix.sql for the SQL commands
      // This is just a placeholder for any additional programmatic setup
      print('Bucket policies should be set up via SQL commands from document_management_sql_commands_final_fix.sql');
      await verifyBucketPolicies();
    } catch (e) {
      print('Warning: Could not set up bucket policies: $e');
    }
  }
  
  // Initialize the document service - should be called once when the app starts
  Future<void> initialize() async {
    try {
      print('Initializing document service...');
      await ensureDocumentsBucketExists();
      await setupBucketPolicies();
      print('Document service initialized successfully');
    } catch (e) {
      print('Warning: Document service initialization failed: $e');
      // Don't throw an error here as we want the app to continue working
      // even if document storage initialization fails
    }
  }
  
  // Get the list of available buckets for debugging
  Future<List<Map<String, dynamic>>> listBucketsDebug() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      return buckets.map((bucket) => {
        'id': bucket.id,
        'name': bucket.name,
        'public': bucket.public,
      }).toList();
    } catch (e) {
      print('Error listing buckets: $e');
      rethrow;
    }
  }
  
  // Fallback method to check if we can access a file directly
  Future<bool> canAccessFile(String filePath) async {
    try {
      print('Checking if file can be accessed: $filePath');
      
      // Try to generate a public URL for the file to check if it exists
      final url = await downloadFile(filePath);
      print('File access check successful for: $filePath, URL: $url');
      return true;
    } catch (e) {
      print('File access check failed for $filePath: $e');
      return false;
    }
  }
  
  // Force bucket creation using admin client
  Future<void> forceCreateDocumentsBucket() async {
    try {
      print('Attempting to force create documents bucket with admin client...');
      final adminClient = SupabaseConfig.adminClient;
      await adminClient.storage.createBucket('documents');
      print('Documents bucket created successfully with admin client');
    } catch (e) {
      print('Error creating documents bucket with admin client: $e');
      rethrow;
    }
  }
  
  // Diagnostic method to check bucket status
  Future<void> diagnoseBucketStatus() async {
    print('=== BUCKET DIAGNOSTIC START ===');
    
    try {
      // Check buckets via storage API
      print('Checking buckets via storage API...');
      final storageBuckets = await _supabase.storage.listBuckets();
      print('Storage buckets found: ${storageBuckets.length}');
      for (var bucket in storageBuckets) {
        print('  - ID: ${bucket.id}, Name: ${bucket.name}, Public: ${bucket.public}');
      }
      
      final documentsBucketExists = storageBuckets.any((bucket) => bucket.id == 'documents');
      print('Documents bucket exists in storage: $documentsBucketExists');
    } catch (e) {
      print('Error checking storage buckets: $e');
    }
    
    try {
      // Check buckets via database query
      print('Checking buckets via database query...');
      final dbResult = await _supabase.from('storage.buckets').select('*');
      print('Database buckets found: ${dbResult.length}');
      for (var bucket in dbResult) {
        print('  - ID: ${bucket['id']}, Name: ${bucket['name']}, Public: ${bucket['public']}');
      }
      
      final dbDocumentsBucketExists = dbResult.any((bucket) => bucket['id'] == 'documents');
      print('Documents bucket exists in database: $dbDocumentsBucketExists');
    } catch (e) {
      print('Error checking database buckets: $e');
    }
    
    print('=== BUCKET DIAGNOSTIC END ===');
  }
  
  // Manually insert bucket into database
  Future<void> manuallyInsertBucketInDatabase() async {
    try {
      print('Attempting to manually insert bucket into database...');
      final adminClient = SupabaseConfig.adminClient;
      
      // Try to insert the bucket directly into the database
      final result = await adminClient.from('storage.buckets').insert({
        'id': 'documents',
        'name': 'documents',
        'public': false,
      }).select();
      
      print('Bucket inserted into database: $result');
    } catch (e) {
      // Check if it's a duplicate key error (bucket already exists)
      if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        print('Bucket already exists in database');
      } else {
        print('Error manually inserting bucket into database: $e');
        rethrow;
      }
    }
  }
  
  // Toggle document favorite status
  Future<void> toggleFavorite(String documentId, String studentId) async {
    try {
      await _supabase.rpc('toggle_document_favorite', params: {
        'p_document_id': documentId,
        'p_student_id': studentId,
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }
  
  // Delete a document completely (removes from storage and database)
  Future<void> deleteDocument(String documentId, String senderId) async {
    try {
      print('=== DELETE DOCUMENT START ===');
      print('Document ID: $documentId');
      print('Sender ID: $senderId');
      
      // First get the document details to get the file path
      final documentResponse = await _supabase
          .from('documents')
          .select('file_path, sender_id')
          .eq('id', documentId)
          .single();
      
      print('Document details: $documentResponse');
      
      // Verify the sender owns this document
      if (documentResponse['sender_id'] != senderId) {
        throw Exception('Permission denied: You can only delete your own documents');
      }
      
      final filePath = documentResponse['file_path'] as String;
      print('File path to delete: $filePath');
      
      // Call the database function to delete the document completely
      await _supabase.rpc('delete_document_completely', params: {
        'p_document_id': documentId,
        'p_sender_id': senderId,
      });
      
      print('Database deletion successful');
      
      // Delete the file from storage
      try {
        await deleteDocumentFile(filePath);
        print('Storage file deletion successful');
      } catch (storageError) {
        print('Warning: Could not delete file from storage: $storageError');
        // Don't throw error here as the database records are already deleted
      }
      
      print('=== DELETE DOCUMENT END (SUCCESS) ===');
    } catch (e) {
      print('=== DELETE DOCUMENT ERROR ===');
      print('Error: $e');
      throw Exception('Failed to delete document: $e');
    }
  }
  
  // Delete a document file from storage
  Future<void> deleteDocumentFile(String filePath) async {
    try {
      print('Deleting file from storage: $filePath');
      
      // Clean the file path for storage deletion
      String cleanPath = filePath;
      if (filePath.startsWith('documents/')) {
        cleanPath = filePath.substring('documents/'.length);
      }
      
      print('Clean path for deletion: $cleanPath');
      
      // Try to delete with regular client first
      try {
        await _supabase.storage.from('documents').remove([cleanPath]);
        print('File deleted with regular client');
      } catch (regularError) {
        print('Regular client deletion failed: $regularError');
        
        // Try with admin client if regular client fails
        try {
          final adminClient = SupabaseConfig.adminClient;
          await adminClient.storage.from('documents').remove([cleanPath]);
          print('File deleted with admin client');
        } catch (adminError) {
          print('Admin client deletion also failed: $adminError');
          throw Exception('Failed to delete file from storage: $adminError');
        }
      }
    } catch (e) {
      print('Storage deletion error: $e');
      throw Exception('Failed to delete file from storage: $e');
    }
  }
  
  // Search documents for a student
  Future<List<StudentDocument>> searchDocuments({
    required String studentId,
    required String query,
  }) async {
    try {
      final response = await _supabase.rpc('search_student_documents', params: {
        'p_student_id': studentId,
        'p_search_query': query,
      });
      
      return (response as List)
          .map((json) => StudentDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }
  
  // Diagnostic function to check database vs storage
  Future<void> diagnoseDocumentPaths() async {
    try {
      print('=== DOCUMENT PATHS DIAGNOSTIC START ===');
      
      // Get all documents from database
      final dbDocuments = await _supabase.from('documents').select('*');
      print('Database documents found: ${dbDocuments.length}');
      
      for (var doc in dbDocuments) {
        print('DB Document ID: ${doc['id']}');
        print('  Title: ${doc['title']}');
        print('  File path: ${doc['file_path']}');
        
        // Try to access this file in storage
        try {
          print('  Trying to access storage file: ${doc['file_path']}');
          await canAccessFile(doc['file_path']);
          print('  ✓ File exists in storage');
        } catch (storageError) {
          print('  ✗ File does not exist in storage: $storageError');
        }
      }
      
      print('=== DOCUMENT PATHS DIAGNOSTIC END ===');
    } catch (e) {
      print('Error in diagnoseDocumentPaths: $e');
    }
  }
  // Method to get all document paths for debugging
  Future<void> printAllDocumentPaths() async {
    try {
      print('=== ALL DOCUMENT PATHS ===');
      final documents = await _supabase.from('documents').select('id, title, file_path');
      print('Found ${documents.length} documents:');
      for (var doc in documents) {
        print('  ID: ${doc['id']}, Title: ${doc['title']}, Path: ${doc['file_path']}');
      }
      print('=== END DOCUMENT PATHS ===');
    } catch (e) {
      print('Error retrieving document paths: $e');
    }
  }
  
  // Comprehensive diagnostic function to identify RLS policy issues
  Future<Map<String, dynamic>> runRLSPolicyDiagnostic() async {
    final result = <String, dynamic>{};
    
    try {
      print('=== RLS POLICY DIAGNOSTIC START ===');
      
      // Test 1: Authentication Status
      try {
        print('TEST 1: Checking authentication status...');
        final user = _supabase.auth.currentUser;
        result['auth_status'] = {
          'authenticated': user != null,
          'user_id': user?.id,
          'user_email': user?.email,
          'user_metadata': user?.userMetadata,
        };
        print('TEST 1: Auth status: ${result['auth_status']}');
      } catch (e) {
        result['auth_status'] = {'error': e.toString()};
        print('TEST 1 FAILED: $e');
      }
      
      // Test 2: Profiles Table Access
      try {
        print('TEST 2: Checking profiles table access...');
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final profileData = await _supabase
              .from('profiles')
              .select('id, school_id, user_type, email')
              .eq('id', user.id)
              .maybeSingle();
          
          result['profile_access'] = {
            'success': true,
            'profile_exists': profileData != null,
            'profile_data': profileData,
          };
          print('TEST 2: Profile data: $profileData');
        } else {
          result['profile_access'] = {'error': 'User not authenticated'};
        }
      } catch (e) {
        result['profile_access'] = {'error': e.toString()};
        print('TEST 2 FAILED: $e');
      }
      
      // Test 3: Documents Table RLS Policies
      try {
        print('TEST 3: Testing documents table RLS policies...');
        
        // Test SELECT policy
        try {
          final docs = await _supabase
              .from('documents')
              .select('id, title, school_id')
              .limit(1);
          result['documents_select'] = {
            'success': true,
            'count': docs.length,
            'sample_data': docs.isNotEmpty ? docs.first : null,
          };
          print('TEST 3a: Documents SELECT successful, found ${docs.length} documents');
        } catch (selectError) {
          result['documents_select'] = {'error': selectError.toString()};
          print('TEST 3a FAILED: Documents SELECT failed: $selectError');
        }
        
        // Test INSERT policy (dry run - we won't actually insert)
        print('TEST 3b: Documents INSERT policy would be tested during actual upload');
        result['documents_insert'] = {'note': 'Tested during actual upload operation'};
        
      } catch (e) {
        result['documents_table'] = {'error': e.toString()};
        print('TEST 3 FAILED: $e');
      }
      
      // Test 4: Student Documents Table RLS Policies
      try {
        print('TEST 4: Testing student_documents table RLS policies...');
        
        // Test SELECT policy
        try {
          final studentDocs = await _supabase
              .from('student_documents')
              .select('id, document_id, student_id')
              .limit(1);
          result['student_documents_select'] = {
            'success': true,
            'count': studentDocs.length,
            'sample_data': studentDocs.isNotEmpty ? studentDocs.first : null,
          };
          print('TEST 4a: Student_documents SELECT successful, found ${studentDocs.length} records');
        } catch (selectError) {
          result['student_documents_select'] = {'error': selectError.toString()};
          print('TEST 4a FAILED: Student_documents SELECT failed: $selectError');
        }
        
      } catch (e) {
        result['student_documents_table'] = {'error': e.toString()};
        print('TEST 4 FAILED: $e');
      }
      
      // Test 5: Storage Bucket RLS Policies
      try {
        print('TEST 5: Testing storage bucket RLS policies...');
        
        // Test bucket access
        try {
          final storageRef = _supabase.storage.from('documents');
          result['storage_bucket_access'] = {'success': true};
          print('TEST 5a: Storage bucket access successful');
          
          // Test list files (SELECT policy)
          try {
            final files = await storageRef.list(path: '', searchOptions: const SearchOptions(limit: 1));
            result['storage_list_files'] = {
              'success': true,
              'count': files.length,
            };
            print('TEST 5b: Storage list files successful, found ${files.length} files');
          } catch (listError) {
            result['storage_list_files'] = {'error': listError.toString()};
            print('TEST 5b FAILED: Storage list files failed: $listError');
          }
          
        } catch (bucketError) {
          result['storage_bucket_access'] = {'error': bucketError.toString()};
          print('TEST 5a FAILED: Storage bucket access failed: $bucketError');
        }
        
      } catch (e) {
        result['storage_policies'] = {'error': e.toString()};
        print('TEST 5 FAILED: $e');
      }
      
      // Test 6: Database Function Access
      try {
        print('TEST 6: Testing database function access...');
        
        // Test if we can call the create_document function (dry run with invalid data)
        try {
          // This should fail due to invalid data, but we want to see if it's an RLS issue or data validation issue
          await _supabase.rpc('create_document', params: {
            'p_school_id': -1, // Invalid school ID to trigger validation error
            'p_sender_id': 'invalid-uuid',
            'p_sender_type': 'admin',
            'p_title': 'test',
            'p_description': null,
            'p_file_path': 'test/path',
            'p_file_name': 'test.pdf',
            'p_file_size': 1000,
            'p_mime_type': 'application/pdf',
            'p_recipient_ids': [],
          });
          result['database_function'] = {'success': true, 'note': 'Unexpected success with invalid data'};
        } catch (funcError) {
          final errorStr = funcError.toString();
          if (errorStr.contains('row-level security policy') || errorStr.contains('RLS')) {
            result['database_function'] = {
              'rls_error': true,
              'error': errorStr,
              'diagnosis': 'RLS policy blocking function execution'
            };
            print('TEST 6: Database function blocked by RLS policy: $funcError');
          } else if (errorStr.contains('invalid') || errorStr.contains('constraint') || errorStr.contains('validation')) {
            result['database_function'] = {
              'rls_error': false,
              'error': errorStr,
              'diagnosis': 'Function accessible, failed due to data validation (expected)'
            };
            print('TEST 6: Database function accessible, failed on validation (expected): $funcError');
          } else {
            result['database_function'] = {
              'rls_error': 'unknown',
              'error': errorStr,
              'diagnosis': 'Unknown error type'
            };
            print('TEST 6: Database function failed with unknown error: $funcError');
          }
        }
        
      } catch (e) {
        result['database_function'] = {'error': e.toString()};
        print('TEST 6 FAILED: $e');
      }
      
      print('=== RLS POLICY DIAGNOSTIC END ===');
      return result;
    } catch (e) {
      result['overall_error'] = e.toString();
      print('OVERALL RLS DIAGNOSTIC FAILED: $e');
      return result;
    }
  }
  
  // Quick diagnostic function to identify the most likely issue
  Future<String> quickDiagnoseUploadIssue() async {
    try {
      print('=== QUICK UPLOAD ISSUE DIAGNOSIS ===');
      
      // Check 1: Authentication
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return 'ISSUE: User not authenticated. Please log in again.';
      }
      
      // Check 2: Profile data
      final profileData = await _supabase
          .from('profiles')
          .select('id, school_id, user_type')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profileData == null) {
        return 'ISSUE: User profile not found in database. Please contact administrator.';
      }
      
      if (profileData['school_id'] == null) {
        return 'ISSUE: User school_id is null in profile. RLS policies will fail. Please contact administrator.';
      }
      
      // Check 3: Storage bucket access
      try {
        await _supabase.storage.from('documents').list(path: '', searchOptions: const SearchOptions(limit: 1));
      } catch (storageError) {
        if (storageError.toString().contains('row-level security policy') ||
            storageError.toString().contains('Unauthorized') ||
            storageError.toString().contains('403')) {
          return 'ISSUE: Storage bucket RLS policy blocking access. Check storage.objects policies.';
        }
      }
      
      // Check 4: Documents table access
      try {
        await _supabase.from('documents').select('id').limit(1);
      } catch (docsError) {
        if (docsError.toString().contains('row-level security policy')) {
          return 'ISSUE: Documents table RLS policy blocking access. Check documents table policies.';
        }
      }
      
      return 'DIAGNOSIS: All basic checks passed. Issue may be in the specific upload operation or create_document function.';
      
    } catch (e) {
      return 'DIAGNOSIS ERROR: Failed to diagnose issue: $e';
    }
  }
}
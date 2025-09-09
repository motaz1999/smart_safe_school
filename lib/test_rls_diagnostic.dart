import 'package:flutter/material.dart';
import 'services/document_service.dart';
import 'core/config/supabase_config.dart';

/// Test script to diagnose RLS policy issues
/// Run this to identify the exact cause of the StorageException
class RLSDiagnosticTest {
  static final DocumentService _documentService = DocumentService();
  
  /// Run comprehensive RLS diagnostic
  static Future<void> runFullDiagnostic() async {
    print('🔍 Starting RLS Policy Diagnostic Test...');
    print('=' * 50);
    
    try {
      // Initialize Supabase if not already done
      await SupabaseConfig.initialize();
      
      // Run quick diagnosis first
      print('📋 QUICK DIAGNOSIS:');
      final quickResult = await _documentService.quickDiagnoseUploadIssue();
      print('Result: $quickResult');
      print('');
      
      // Run comprehensive diagnostic
      print('🔬 COMPREHENSIVE DIAGNOSTIC:');
      final fullResult = await _documentService.runRLSPolicyDiagnostic();
      
      print('📊 DIAGNOSTIC RESULTS SUMMARY:');
      print('=' * 30);
      
      // Authentication Status
      final authStatus = fullResult['auth_status'];
      if (authStatus != null) {
        print('🔐 Authentication: ${authStatus['authenticated'] ? '✅ PASSED' : '❌ FAILED'}');
        if (authStatus['authenticated']) {
          print('   User ID: ${authStatus['user_id']}');
          print('   Email: ${authStatus['user_email']}');
        }
      }
      
      // Profile Access
      final profileAccess = fullResult['profile_access'];
      if (profileAccess != null) {
        if (profileAccess['success'] == true) {
          print('👤 Profile Access: ✅ PASSED');
          final profileData = profileAccess['profile_data'];
          if (profileData != null) {
            print('   School ID: ${profileData['school_id']}');
            print('   User Type: ${profileData['user_type']}');
            if (profileData['school_id'] == null) {
              print('   ⚠️  WARNING: school_id is null - this will cause RLS failures!');
            }
          } else {
            print('   ❌ Profile not found in database');
          }
        } else {
          print('👤 Profile Access: ❌ FAILED');
          print('   Error: ${profileAccess['error']}');
        }
      }
      
      // Documents Table Access
      final docsSelect = fullResult['documents_select'];
      if (docsSelect != null) {
        print('📄 Documents Table SELECT: ${docsSelect['success'] == true ? '✅ PASSED' : '❌ FAILED'}');
        if (docsSelect['success'] == true) {
          print('   Found ${docsSelect['count']} documents');
        } else {
          print('   Error: ${docsSelect['error']}');
        }
      }
      
      // Student Documents Table Access
      final studentDocsSelect = fullResult['student_documents_select'];
      if (studentDocsSelect != null) {
        print('📋 Student Documents Table SELECT: ${studentDocsSelect['success'] == true ? '✅ PASSED' : '❌ FAILED'}');
        if (studentDocsSelect['success'] == true) {
          print('   Found ${studentDocsSelect['count']} student document records');
        } else {
          print('   Error: ${studentDocsSelect['error']}');
        }
      }
      
      // Storage Bucket Access
      final storageBucketAccess = fullResult['storage_bucket_access'];
      if (storageBucketAccess != null) {
        print('🗄️  Storage Bucket Access: ${storageBucketAccess['success'] == true ? '✅ PASSED' : '❌ FAILED'}');
        if (storageBucketAccess['success'] != true) {
          print('   Error: ${storageBucketAccess['error']}');
        }
      }
      
      final storageListFiles = fullResult['storage_list_files'];
      if (storageListFiles != null) {
        print('📁 Storage List Files: ${storageListFiles['success'] == true ? '✅ PASSED' : '❌ FAILED'}');
        if (storageListFiles['success'] == true) {
          print('   Found ${storageListFiles['count']} files in storage');
        } else {
          print('   Error: ${storageListFiles['error']}');
        }
      }
      
      // Database Function Access
      final dbFunction = fullResult['database_function'];
      if (dbFunction != null) {
        if (dbFunction['rls_error'] == true) {
          print('⚙️  Database Function: ❌ BLOCKED BY RLS');
          print('   Diagnosis: ${dbFunction['diagnosis']}');
          print('   Error: ${dbFunction['error']}');
        } else if (dbFunction['rls_error'] == false) {
          print('⚙️  Database Function: ✅ ACCESSIBLE');
          print('   Diagnosis: ${dbFunction['diagnosis']}');
        } else {
          print('⚙️  Database Function: ❓ UNKNOWN');
          print('   Error: ${dbFunction['error']}');
        }
      }
      
      print('');
      print('🎯 RECOMMENDATIONS:');
      print('=' * 20);
      
      // Generate recommendations based on results
      if (authStatus?['authenticated'] != true) {
        print('❗ CRITICAL: User not authenticated. Please log in first.');
      } else if (profileAccess?['profile_data']?['school_id'] == null) {
        print('❗ CRITICAL: User profile missing school_id. This will cause all RLS policies to fail.');
        print('   Fix: UPDATE profiles SET school_id = [correct_school_id] WHERE id = \'${authStatus?['user_id']}\';');
      } else if (storageBucketAccess?['success'] != true) {
        print('❗ ISSUE: Storage bucket access failed. Check storage.objects RLS policies.');
        print('   The policies in document_management_sql_commands_final_fix.sql may need to be re-applied.');
      } else if (dbFunction?['rls_error'] == true) {
        print('❗ ISSUE: Database function blocked by RLS policies.');
        print('   Check documents and student_documents table RLS policies.');
      } else {
        print('✅ All basic checks passed. The issue may be in the specific upload operation.');
        print('   Try uploading a file and check the detailed logs for the exact failure point.');
      }
      
    } catch (e) {
      print('❌ Diagnostic test failed: $e');
    }
    
    print('');
    print('🏁 Diagnostic test completed.');
    print('=' * 50);
  }
  
  /// Test storage bucket comprehensive diagnostic
  static Future<void> testStorageBucketDiagnostic() async {
    print('🗄️  Running Storage Bucket Comprehensive Diagnostic...');
    
    try {
      final result = await _documentService.runComprehensiveBucketDiagnostic();
      
      print('📊 STORAGE DIAGNOSTIC RESULTS:');
      print('Storage API Success: ${result['storage_api_success']}');
      print('Available Buckets: ${result['available_buckets']}');
      print('Documents Bucket Exists (Storage): ${result['documents_bucket_exists_storage']}');
      print('Documents Bucket Exists (DB): ${result['documents_bucket_exists_db']}');
      print('Bucket Access Success: ${result['bucket_access_success']}');
      print('List Files Success: ${result['bucket_list_files_success']}');
      print('Get Public URL Success: ${result['get_public_url_success']}');
      print('User Authenticated: ${result['user_authenticated']}');
      
      if (result['storage_api_error'] != null) {
        print('Storage API Error: ${result['storage_api_error']}');
      }
      if (result['bucket_access_error'] != null) {
        print('Bucket Access Error: ${result['bucket_access_error']}');
      }
      if (result['bucket_list_files_error'] != null) {
        print('List Files Error: ${result['bucket_list_files_error']}');
      }
      
    } catch (e) {
      print('Storage diagnostic failed: $e');
    }
  }
}

/// Main function to run the diagnostic
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting RLS Diagnostic Test Suite...');
  
  // Run full diagnostic
  await RLSDiagnosticTest.runFullDiagnostic();
  
  print('');
  
  // Run storage diagnostic
  await RLSDiagnosticTest.testStorageBucketDiagnostic();
  
  print('');
  print('✨ All diagnostic tests completed!');
  print('');
  print('📝 NEXT STEPS:');
  print('1. Review the diagnostic results above');
  print('2. Fix any identified issues (especially missing school_id in profiles)');
  print('3. Try uploading a file again');
  print('4. Check the detailed logs in the upload functions for specific error details');
}
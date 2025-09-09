# Supabase Storage Troubleshooting Guide

## Problem Diagnosed
**Error**: `Failed to download document: Exception: Storage error: Exception: Failed to verify bucket existence: Exception: Documents bucket not found in storage`

**Root Cause**: Supabase Storage is either not enabled or not properly configured in your project.

## Diagnostic Results Summary
- ❌ **No storage buckets exist** (Available Buckets: [])
- ❌ **Documents bucket missing** (Documents bucket exists: false)
- ❌ **Storage schema not accessible** (relation "public.storage.buckets" does not exist)
- ❌ **User not authenticated** (affects bucket creation permissions)
- ✅ **Supabase connection works** (can generate URLs)

## Step-by-Step Verification & Fix

### Step 1: Verify Supabase Storage is Enabled

1. **Go to your Supabase Dashboard**:
   - Visit: https://supabase.com/dashboard
   - Navigate to your project: `tycjmxjiatsxtbldyaug`

2. **Check Storage Tab**:
   - Click on **"Storage"** in the left sidebar
   - If you see "Storage is not enabled" or similar message, Storage needs to be enabled
   - If Storage is enabled, you should see a list of buckets (currently empty)

3. **Enable Storage** (if not enabled):
   - Look for an "Enable Storage" button or similar
   - Click to enable Storage for your project
   - Wait for the setup to complete

### Step 2: Verify Storage Schema

1. **Go to SQL Editor**:
   - Click on **"SQL Editor"** in the left sidebar
   - Run this query to check if storage schema exists:

```sql
-- Check if storage schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'storage';

-- Check if storage.buckets table exists
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'storage' AND table_name = 'buckets';
```

2. **Expected Results**:
   - First query should return: `storage`
   - Second query should return: `buckets`
   - If either fails, Storage is not properly enabled

### Step 3: Create Documents Bucket

1. **Option A: Via Dashboard** (Recommended):
   - Go to **Storage** tab
   - Click **"New bucket"** or **"Create bucket"**
   - Bucket name: `documents`
   - Make it **Private** (not public)
   - Click **"Create bucket"**

2. **Option B: Via SQL** (if dashboard doesn't work):
   - Go to **SQL Editor**
   - Run the bucket creation commands:

```sql
-- Create the documents bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;
```

### Step 4: Set Up Storage Policies

Run these SQL commands in the **SQL Editor**:

```sql
-- Storage policies for documents bucket
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow upload to documents bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow read from documents bucket" ON storage.objects;

-- Allow authenticated users to upload to documents bucket
CREATE POLICY "Allow upload to documents bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
);

-- Allow authenticated users to read from documents bucket
CREATE POLICY "Allow read from documents bucket"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
);
```

### Step 5: Verify the Fix

1. **Run the diagnostic test again**:
```bash
flutter run lib/test_bucket_diagnostic.dart -d chrome
```

2. **Expected Results After Fix**:
   - ✅ `Available Buckets: ['documents']`
   - ✅ `Documents bucket exists: true`
   - ✅ `Storage API Success: true`
   - ✅ `Bucket Access Success: true`

### Step 6: Test Document Download

1. **Try the original functionality** that was failing
2. **The error should be resolved** and documents should download properly

## Common Issues & Solutions

### Issue 1: "Storage is not available"
**Solution**: Enable Storage in your Supabase project settings

### Issue 2: "Permission denied" when creating bucket
**Solution**: 
- Use the Supabase dashboard instead of SQL
- Ensure you're logged in as the project owner
- Check your project's billing status (Storage might require a paid plan)

### Issue 3: "relation storage.buckets does not exist"
**Solution**: 
- Storage extension is not properly installed
- Contact Supabase support or recreate the project with Storage enabled

### Issue 4: Bucket created but still getting errors
**Solution**:
- Check storage policies are correctly set
- Verify user authentication is working
- Clear browser cache and restart the app

## Verification Commands

Use these SQL queries to verify everything is working:

```sql
-- 1. Check if storage schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'storage';

-- 2. List all buckets
SELECT * FROM storage.buckets;

-- 3. Check storage policies
SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';

-- 4. Test bucket access (should return empty list, not error)
SELECT * FROM storage.objects WHERE bucket_id = 'documents' LIMIT 1;
```

## Next Steps After Fix

1. **Test document upload functionality**
2. **Test document download functionality** 
3. **Verify all document management features work**
4. **Remove the diagnostic test file**: `lib/test_bucket_diagnostic.dart`

## Contact Information

If you continue to have issues:
- Check Supabase documentation: https://supabase.com/docs/guides/storage
- Contact Supabase support through their dashboard
- Verify your project's subscription includes Storage features
-- Diagnostic query to check existing policies on documents table
SELECT 
    polname AS policy_name,
    polrelid::regclass AS table_name,
    polcmd AS command_type,
    polroles AS roles,
    polqual AS using_condition,
    polwithcheck AS with_check_condition
FROM pg_policy 
WHERE polrelid = 'documents'::regclass;

-- Check if RLS is enabled on documents table
SELECT 
    relname AS table_name,
    relrowsecurity AS rls_enabled,
    relforcerowsecurity AS force_rls
FROM pg_class 
WHERE relname = 'documents';

-- Check for any functions that might reference documents table
SELECT 
    proname AS function_name,
    prosrc AS function_source
FROM pg_proc 
WHERE prosrc ILIKE '%documents%';

-- Check storage policies
SELECT 
    polname AS policy_name,
    polrelid::regclass AS table_name,
    polcmd AS command_type,
    polroles AS roles,
    polqual AS using_condition,
    polwithcheck AS with_check_condition
FROM pg_policy 
WHERE polrelid = 'storage.objects'::regclass 
AND (polqual ILIKE '%documents%' OR polwithcheck ILIKE '%documents%');
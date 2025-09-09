# Document Management System - Simplified Migration Script

## Overview
This script will migrate the existing document management system to the simplified enhanced version. It will:
1. Drop existing tables and functions
2. Create new tables with enhanced schema
3. Create new functions for document management

## Migration Script

```sql
-- Document Management System - Simplified Migration Script

-- First, drop existing functions that reference the old tables
DROP FUNCTION IF EXISTS create_document(
  p_school_id INTEGER,
  p_sender_id UUID,
  p_sender_type TEXT,
  p_title TEXT,
  p_description TEXT,
  p_file_path TEXT,
  p_file_name TEXT,
  p_file_size INTEGER,
  p_mime_type TEXT,
  p_recipient_ids UUID[]
);

DROP FUNCTION IF EXISTS get_student_documents(p_student_id UUID);
DROP FUNCTION IF EXISTS mark_document_as_read(p_document_id UUID, p_student_id UUID);
DROP FUNCTION IF EXISTS get_users_by_type(p_school_id INTEGER, p_user_type TEXT, p_limit INTEGER, p_offset INTEGER);

-- Drop existing tables (in correct order to avoid foreign key conflicts)
DROP TABLE IF EXISTS student_documents CASCADE;
DROP TABLE IF EXISTS documents CASCADE;

-- Create the documents table with enhanced structure
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER NOT NULL,
    sender_id UUID NOT NULL,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('admin', 'teacher')),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT DEFAULT 'application/pdf',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the student_documents table with enhanced structure
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);

-- Add indexes for better query performance
CREATE INDEX idx_documents_school_id ON documents(school_id);
CREATE INDEX idx_documents_sender_id ON documents(sender_id);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_student_documents_document_id ON student_documents(document_id);
CREATE INDEX idx_student_documents_student_id ON student_documents(student_id);
CREATE INDEX idx_student_documents_is_read ON student_documents(is_read);
CREATE INDEX idx_student_documents_is_favorite ON student_documents(is_favorite);

-- Create enhanced functions for document management

-- Function to create a document and associate it with students
CREATE OR REPLACE FUNCTION create_document(
  p_school_id INTEGER,
  p_sender_id UUID,
  p_sender_type TEXT,
  p_title TEXT,
  p_description TEXT,
  p_file_path TEXT,
  p_file_name TEXT,
  p_file_size INTEGER,
  p_mime_type TEXT,
  p_recipient_ids UUID[]
)
RETURNS UUID AS $$
DECLARE
  document_id UUID;
BEGIN
  -- Create document record
  INSERT INTO documents (
    school_id, sender_id, sender_type, title, description,
    file_path, file_name, file_size, mime_type
  )
  VALUES (
    p_school_id, p_sender_id, p_sender_type, p_title, p_description,
    p_file_path, p_file_name, p_file_size, p_mime_type
  )
  RETURNING id INTO document_id;
  
  -- Create student_document records for each recipient
  INSERT INTO student_documents (document_id, student_id)
  SELECT document_id, UNNEST(p_recipient_ids);
  
  RETURN document_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get documents for a specific student
CREATE OR REPLACE FUNCTION get_student_documents(p_student_id UUID)
RETURNS TABLE(
  id UUID,
  document_id UUID,
  document_title TEXT,
  sender_name TEXT,
  created_at TIMESTAMPTZ,
  is_read BOOLEAN,
  is_favorite BOOLEAN,
  read_at TIMESTAMPTZ,
  file_path TEXT,
  file_name TEXT,
  file_size INTEGER,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sd.id,
    sd.document_id,
    d.title as document_title,
    '' as sender_name, -- We'll populate this in the application code
    d.created_at,
    sd.is_read,
    sd.is_favorite,
    sd.read_at,
    d.file_path,
    d.file_name,
    d.file_size,
    d.description
  FROM student_documents sd
  JOIN documents d ON sd.document_id = d.id
  WHERE sd.student_id = p_student_id
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to mark a document as read by a student
CREATE OR REPLACE FUNCTION mark_document_as_read(p_document_id UUID, p_student_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE student_documents
  SET is_read = TRUE,
      read_at = NOW()
  WHERE document_id = p_document_id AND student_id = p_student_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to toggle document favorite status
CREATE OR REPLACE FUNCTION toggle_document_favorite(p_document_id UUID, p_student_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_favorite BOOLEAN;
BEGIN
  -- Get current favorite status
  SELECT is_favorite INTO current_favorite
  FROM student_documents
  WHERE document_id = p_document_id AND student_id = p_student_id;
  
  -- Toggle the status
  UPDATE student_documents
  SET is_favorite = NOT current_favorite
  WHERE document_id = p_document_id AND student_id = p_student_id;
  
  RETURN NOT current_favorite;
END;
$$ LANGUAGE plpgsql;

-- Function to get document statistics
CREATE OR REPLACE FUNCTION get_document_stats(p_document_id UUID)
RETURNS TABLE(
    total_recipients INTEGER,
    read_count INTEGER,
    favorite_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_recipients,
        COUNT(CASE WHEN sd.is_read THEN 1 END)::INTEGER as read_count,
        COUNT(CASE WHEN sd.is_favorite THEN 1 END)::INTEGER as favorite_count
    FROM student_documents sd
    WHERE sd.document_id = p_document_id;
END;
$$ LANGUAGE plpgsql;

-- Function to search student documents
CREATE OR REPLACE FUNCTION search_student_documents(p_student_id UUID, p_search_query TEXT)
RETURNS TABLE(
  id UUID,
  document_id UUID,
  document_title TEXT,
  sender_name TEXT,
  created_at TIMESTAMPTZ,
  is_read BOOLEAN,
  is_favorite BOOLEAN,
  read_at TIMESTAMPTZ,
  file_path TEXT,
  file_name TEXT,
  file_size INTEGER,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sd.id,
    sd.document_id,
    d.title as document_title,
    '' as sender_name,
    d.created_at,
    sd.is_read,
    sd.is_favorite,
    sd.read_at,
    d.file_path,
    d.file_name,
    d.file_size,
    d.description
  FROM student_documents sd
  JOIN documents d ON sd.document_id = d.id
  WHERE sd.student_id = p_student_id
    AND (d.title ILIKE '%' || p_search_query || '%' 
         OR d.description ILIKE '%' || p_search_query || '%')
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Storage policies (if needed)
-- Note: These should be reviewed based on your specific security requirements
-- First drop existing policies if they exist
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

## Usage Instructions

1. **Backup your database** before running this script
2. Execute the script in your Supabase SQL editor
3. Verify that all tables and functions were created successfully
4. Test the new functionality with your application

## Notes

- This script completely replaces the old document management schema
- All existing data will be lost - make sure to backup if needed
- The new functions provide enhanced capabilities while maintaining compatibility
- Indexes have been added for better query performance
- Storage policies are included but should be reviewed for your security requirements
- Policies are dropped and recreated to avoid conflicts
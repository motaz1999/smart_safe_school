-- Document Management SQL Commands - Final Fix
-- This version completely eliminates recursion by using a different approach

-- First, let's drop any existing documents table and related objects
DROP TABLE IF EXISTS student_documents CASCADE;
DROP TABLE IF EXISTS documents CASCADE;

-- Create the documents table with a simpler structure
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

-- Create the student_documents table
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,  -- New column for favorite status
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);

-- Add indexes for better query performance
CREATE INDEX idx_documents_school_id ON documents(school_id);
CREATE INDEX idx_documents_sender_id ON documents(sender_id);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_student_documents_document_id ON student_documents(document_id);
CREATE INDEX idx_student_documents_student_id ON student_documents(student_id);
CREATE INDEX idx_student_documents_is_read ON student_documents(is_read);
CREATE INDEX idx_student_documents_is_favorite ON student_documents(is_favorite);  -- New index

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
  is_favorite BOOLEAN,  -- New column
  file_path TEXT,
  file_name TEXT,
  file_size INTEGER
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
    sd.is_favorite,  -- New column
    d.file_path,
    d.file_name,
    d.file_size
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
  SET is_read = TRUE
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
  
  -- Toggle the favorite status
  UPDATE student_documents
  SET is_favorite = NOT current_favorite
  WHERE document_id = p_document_id AND student_id = p_student_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to search documents for a student
CREATE OR REPLACE FUNCTION search_student_documents(p_student_id UUID, p_search_query TEXT)
RETURNS TABLE(
  id UUID,
  document_id UUID,
  document_title TEXT,
  sender_name TEXT,
  created_at TIMESTAMPTZ,
  is_read BOOLEAN,
  is_favorite BOOLEAN,
  file_path TEXT,
  file_name TEXT,
  file_size INTEGER
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
    d.file_path,
    d.file_name,
    d.file_size
  FROM student_documents sd
  JOIN documents d ON sd.document_id = d.id
  WHERE sd.student_id = p_student_id
    AND (d.title ILIKE '%' || p_search_query || '%' OR d.description ILIKE '%' || p_search_query || '%')
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS on documents table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Enable RLS on student_documents table
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;

-- Create the documents bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies - Minimal to avoid any recursion
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Students can read received documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can read their own documents" ON storage.objects;

-- Allow authenticated users to upload to documents bucket
-- We'll control access via application logic
CREATE POLICY "Allow upload to documents bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
);

-- Allow authenticated users to read from documents bucket
-- We'll control access via application logic
CREATE POLICY "Allow read from documents bucket"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
);

-- Document table RLS policies - Simplified to avoid recursion

-- Users can only view documents from their school
CREATE POLICY "Users can view school documents"
ON documents FOR SELECT
TO authenticated
USING (
  school_id = (SELECT school_id FROM profiles WHERE id = auth.uid() LIMIT 1)
);

-- Allow inserts for documents (controlled by application logic)
CREATE POLICY "Allow document creation"
ON documents FOR INSERT
TO authenticated
WITH CHECK (
  school_id = (SELECT school_id FROM profiles WHERE id = auth.uid() LIMIT 1)
);

-- Users can only view document relationships for their school
CREATE POLICY "Users can view school document relationships"
ON student_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM documents d 
    WHERE d.id = student_documents.document_id 
    AND d.school_id = (SELECT school_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  )
);

-- Allow inserts for student_documents (controlled by application logic)
CREATE POLICY "Allow student_document creation"
ON student_documents FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM documents d 
    WHERE d.id = student_documents.document_id 
    AND d.school_id = (SELECT school_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  )
);
-- Document Management SQL Commands - Integrated Version
-- This version integrates with the existing database setup to avoid policy conflicts

-- Create the documents table
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('admin', 'teacher')),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT DEFAULT 'application/pdf',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_documents_school_id ON documents(school_id);
CREATE INDEX IF NOT EXISTS idx_documents_sender_id ON documents(sender_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at);

-- Create the student_documents table
CREATE TABLE IF NOT EXISTS student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_student_documents_document_id ON student_documents(document_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_student_id ON student_documents(student_id);
CREATE INDEX IF NOT EXISTS idx_student_documents_is_read ON student_documents(is_read);

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
    p.name as sender_name,
    d.created_at,
    sd.is_read,
    d.file_path,
    d.file_name,
    d.file_size
  FROM student_documents sd
  JOIN documents d ON sd.document_id = d.id
  JOIN profiles p ON d.sender_id = p.id
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

-- Create the documents bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Students can read received documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can read their own documents" ON storage.objects;

-- Admins can upload documents
CREATE POLICY "Admins can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents' 
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'admin'
    AND profiles.school_id = (SELECT school_id FROM documents WHERE file_path = storage.objects.name LIMIT 1)
  )
);

-- Teachers can upload documents
CREATE POLICY "Teachers can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents' 
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'teacher'
    AND profiles.school_id = (SELECT school_id FROM documents WHERE file_path = storage.objects.name LIMIT 1)
  )
);

-- Students can read documents sent to them
CREATE POLICY "Students can read received documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1 FROM student_documents sd
    JOIN documents d ON sd.document_id = d.id
    WHERE sd.student_id = auth.uid()
    AND d.file_path = storage.objects.name
  )
);

-- Admins and teachers can read their own uploaded documents
CREATE POLICY "Users can read their own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND owner = auth.uid()
);

-- Document table RLS policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can view school documents" ON documents;
DROP POLICY IF EXISTS "Teachers can view their documents" ON documents;
DROP POLICY IF EXISTS "Students can view received documents" ON documents;
DROP POLICY IF EXISTS "Students can view their document relationships" ON student_documents;
DROP POLICY IF EXISTS "Senders can view document relationships" ON student_documents;

-- Enable RLS on documents table if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'documents'::regclass) THEN
    ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Enable RLS on student_documents table if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'student_documents'::regclass) THEN
    ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Admins can view all documents in their school
CREATE POLICY "Admins can view school documents"
ON documents FOR SELECT
TO authenticated
USING (
  school_id IN (
    SELECT school_id FROM profiles WHERE id = auth.uid()
  )
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'admin'
  )
);

-- Teachers can view documents they sent
CREATE POLICY "Teachers can view their documents"
ON documents FOR SELECT
TO authenticated
USING (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'teacher'
  )
);

-- Students can view documents sent to them
CREATE POLICY "Students can view received documents"
ON documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM student_documents sd
    WHERE sd.document_id = documents.id
    AND sd.student_id = auth.uid()
  )
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'student'
  )
);

-- Student document relationship access policy

-- Students can view their document relationships
CREATE POLICY "Students can view their document relationships"
ON student_documents FOR SELECT
TO authenticated
USING (
  student_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type = 'student'
  )
);

-- Admins and teachers can view document relationships for documents they sent
CREATE POLICY "Senders can view document relationships"
ON student_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM documents d
    WHERE d.id = student_documents.document_id
    AND d.sender_id = auth.uid()
  )
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.user_type IN ('admin', 'teacher')
  )
);
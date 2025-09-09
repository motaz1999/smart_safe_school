# Supabase Document Storage Implementation Plan

## Overview
This document outlines the steps needed to set up document storage in Supabase for the PDF document sending feature.

## Storage Requirements
1. Create a dedicated storage bucket for documents
2. Set up proper access controls using Row Level Security (RLS)
3. Configure storage policies for different user roles
4. Ensure secure and efficient file handling

## Implementation Steps

### 1. Create Documents Storage Bucket
```sql
-- Create the documents bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);
```

### 2. Set Up Storage Policies

#### Policy for Admins
```sql
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
  )
);

-- Admins can read their own uploaded documents
CREATE POLICY "Admins can read their documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND owner = auth.uid()
);
```

#### Policy for Teachers
```sql
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
  )
);

-- Teachers can read their own uploaded documents
CREATE POLICY "Teachers can read their documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND owner = auth.uid()
);
```

#### Policy for Students
```sql
-- Students can read documents sent to them
CREATE POLICY "Students can read received documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1 FROM student_documents sd
    JOIN documents d ON sd.document_id = d.id
    JOIN profiles p ON d.school_id = p.school_id
    WHERE sd.student_id = auth.uid()
    AND d.file_path = storage.objects.name
  )
);
```

### 3. Database Functions for Document Management

#### Function to Create Document Record
```sql
CREATE OR REPLACE FUNCTION create_document(
  p_school_id UUID,
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
```

#### Function to Get Student Documents
```sql
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
```

### 4. Storage Configuration

#### File Naming Convention
- Use UUID-based file names to ensure uniqueness
- Preserve original file extensions
- Example: `a1b2c3d4-e5f6-7890-abcd-ef1234567890.pdf`

#### File Path Structure
- Organize by school ID to maintain separation
- Example: `school_id/document_id/original_filename.pdf`

### 5. Security Considerations

#### Access Control
- Only authenticated users can access storage
- Users can only access files they're authorized to access
- Implement proper error handling for unauthorized access attempts

#### File Validation
- Validate file types on upload (PDF only)
- Implement file size limits
- Sanitize file names

#### Data Retention
- Consider implementing a document retention policy
- Handle document deletion properly (both storage and database records)

### 6. Performance Optimization

#### Caching
- Implement caching for frequently accessed documents
- Use CDN for improved download speeds

#### Indexing
- Add indexes on frequently queried columns:
  ```sql
  CREATE INDEX idx_documents_school_id ON documents(school_id);
  CREATE INDEX idx_documents_sender_id ON documents(sender_id);
  CREATE INDEX idx_student_documents_student_id ON student_documents(student_id);
  CREATE INDEX idx_student_documents_document_id ON student_documents(document_id);
  ```

### 7. Monitoring and Maintenance

#### Storage Monitoring
- Set up alerts for storage usage limits
- Monitor upload/download activity
- Track failed upload attempts

#### Backup Strategy
- Ensure regular backups of document metadata
- Consider backup strategy for actual document files
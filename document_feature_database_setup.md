# Document Feature Database Setup

## Overview
This document outlines the database setup required for the document feature that allows teachers to upload documents from their local PC or smartphone and send them to students.

## Database Tables

### 1. Documents Table
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
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
```

### 2. Student Documents Table
```sql
CREATE TABLE student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_id, student_id)
);
```

## Database Functions

### 1. Create Document Function
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

### 2. Get Student Documents Function
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

### 3. Mark Document as Read Function
```sql
CREATE OR REPLACE FUNCTION mark_document_as_read(p_document_id UUID, p_student_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE student_documents
  SET is_read = TRUE
  WHERE document_id = p_document_id AND student_id = p_student_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;
```

## Storage Setup

### 1. Create Documents Bucket
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;
```

### 2. Storage Policies

#### Admins can upload documents
```sql
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
```

#### Teachers can upload documents
```sql
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
```

#### Students can read documents sent to them
```sql
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
```

#### Users can read their own documents
```sql
CREATE POLICY "Users can read their own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND owner = auth.uid()
);
```

## Row Level Security (RLS) Policies

### Documents Table Policies

#### Admins can view school documents
```sql
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
```

#### Teachers can view their documents
```sql
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
```

#### Students can view received documents
```sql
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
```

### Student Documents Table Policies

#### Students can view their document relationships
```sql
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
```

#### Senders can view document relationships
```sql
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
```

## Implementation Steps

1. Execute the SQL commands in your Supabase SQL editor in the following order:
   - Create tables
   - Create indexes
   - Create functions
   - Create storage bucket
   - Create storage policies
   - Enable RLS on tables
   - Create RLS policies

2. Verify that all commands execute successfully without errors

3. Test the functionality by:
   - Uploading a document as a teacher
   - Checking that it appears in the student's document list
   - Downloading the document as a student
   - Verifying read status updates correctly

## Troubleshooting

### Common Issues

1. **RLS Policy Errors**: Ensure all RLS policies are correctly defined and that users have the appropriate permissions
2. **Storage Policy Errors**: Verify that storage policies are correctly set up for the 'documents' bucket
3. **Function Execution Errors**: Check that all function parameters match the expected types
4. **Foreign Key Constraint Errors**: Ensure referenced tables (schools, profiles) have the correct data

### Debugging Tips

1. Check Supabase logs for detailed error messages
2. Test each component separately (tables, functions, policies)
3. Use Supabase's SQL editor to run queries manually for testing
4. Verify that user authentication is working correctly
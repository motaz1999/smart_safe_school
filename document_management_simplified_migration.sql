-- Document Management Simplified Migration
-- This script updates the existing database schema to add the is_favorite column

-- Add the is_favorite column to student_documents table
ALTER TABLE student_documents
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- Create index for the new column
CREATE INDEX IF NOT EXISTS idx_student_documents_is_favorite ON student_documents(is_favorite);

-- Update the get_student_documents function to include the new column
DROP FUNCTION IF EXISTS get_student_documents(UUID);

CREATE OR REPLACE FUNCTION get_student_documents(p_student_id UUID)
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
  ORDER BY d.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create the toggle_document_favorite function
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

-- Create the search_student_documents function
DROP FUNCTION IF EXISTS search_student_documents(UUID, TEXT);
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
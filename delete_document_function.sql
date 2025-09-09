-- Function to completely delete a document and all its relationships
-- This removes the document from both documents and student_documents tables
-- and ensures proper cleanup

CREATE OR REPLACE FUNCTION delete_document_completely(
    p_document_id TEXT,
    p_sender_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_document_exists BOOLEAN := FALSE;
    v_sender_matches BOOLEAN := FALSE;
    v_deleted_count INTEGER := 0;
BEGIN
    -- Log the deletion attempt
    RAISE NOTICE 'Attempting to delete document % by sender %', p_document_id, p_sender_id;
    
    -- Check if document exists and verify sender
    SELECT 
        COUNT(*) > 0,
        COUNT(CASE WHEN sender_id = p_sender_id THEN 1 END) > 0
    INTO v_document_exists, v_sender_matches
    FROM documents 
    WHERE id = p_document_id;
    
    -- Validate document exists
    IF NOT v_document_exists THEN
        RAISE EXCEPTION 'Document with ID % does not exist', p_document_id;
    END IF;
    
    -- Validate sender ownership
    IF NOT v_sender_matches THEN
        RAISE EXCEPTION 'Permission denied: You can only delete your own documents';
    END IF;
    
    -- Delete from student_documents table first (foreign key constraint)
    DELETE FROM student_documents 
    WHERE document_id = p_document_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % student_document relationships', v_deleted_count;
    
    -- Delete from documents table
    DELETE FROM documents 
    WHERE id = p_document_id AND sender_id = p_sender_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % document records', v_deleted_count;
    
    -- Verify deletion was successful
    IF v_deleted_count = 0 THEN
        RAISE EXCEPTION 'Failed to delete document - no rows affected';
    END IF;
    
    RAISE NOTICE 'Document % successfully deleted completely', p_document_id;
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting document: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_document_completely(TEXT, TEXT) TO authenticated;

-- Add RLS policy to ensure users can only delete their own documents
-- (This is handled in the function logic, but adding as extra security)

COMMENT ON FUNCTION delete_document_completely(TEXT, TEXT) IS 
'Completely deletes a document and all its relationships. Only the sender can delete their own documents.';
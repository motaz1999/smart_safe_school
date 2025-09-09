-- =====================================================
-- Smart Safe School Management System - Complete Database Setup
-- Run this entire script in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. CREATE TABLES
-- =====================================================

-- Schools Table
CREATE TABLE IF NOT EXISTS schools (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Profiles Table (for all user types)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    user_type TEXT NOT NULL CHECK (user_type IN ('admin', 'teacher', 'student')),
    name TEXT NOT NULL,
    user_id TEXT UNIQUE NOT NULL,
    phone TEXT,
    
    -- Admin specific fields
    permissions JSONB DEFAULT '{}',
    
    -- Student specific fields
    class_id UUID,
    parent_contact TEXT,
    gender TEXT CHECK (gender IS NULL OR gender IN ('male', 'female')), -- Added gender field with enum values
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_admin_data CHECK (
        user_type != 'admin' OR (permissions IS NOT NULL)
    ),
    CONSTRAINT valid_student_data CHECK (
        user_type != 'student' OR (class_id IS NOT NULL)
    )
);

-- Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    grade_level TEXT,
    capacity INTEGER DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraint for class_id in profiles
ALTER TABLE profiles ADD CONSTRAINT fk_profiles_class_id 
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL;

-- Subjects Table
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, code)
);

-- Teacher Subjects Junction Table
CREATE TABLE IF NOT EXISTS teacher_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, subject_id)
);

-- Academic Years Table
CREATE TABLE IF NOT EXISTS academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, name)
);

-- Semesters Table
CREATE TABLE IF NOT EXISTS semesters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    semester_number INTEGER NOT NULL CHECK (semester_number IN (1, 2, 3)),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(academic_year_id, semester_number)
);

-- Timetables Table
CREATE TABLE IF NOT EXISTS timetables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    day_of_week TEXT NOT NULL CHECK (day_of_week IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(class_id, day_of_week, start_time)
);

-- Attendance Records Table
CREATE TABLE IF NOT EXISTS attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, subject_id, attendance_date)
);

-- Grades Table
CREATE TABLE IF NOT EXISTS grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    semester_id UUID REFERENCES semesters(id) ON DELETE CASCADE,
    grade_number INTEGER NOT NULL CHECK (grade_number IN (1, 2)),
    grade_value DECIMAL(5,2) NOT NULL,
    max_grade DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, subject_id, semester_id, grade_number)
);

-- =====================================================
-- 2. CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_profiles_school_id ON profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes(school_id);
CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects(school_id);
CREATE INDEX IF NOT EXISTS idx_timetables_class_id ON timetables(class_id);
CREATE INDEX IF NOT EXISTS idx_timetables_teacher_id ON timetables(teacher_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON attendance_records(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(attendance_date);
CREATE INDEX IF NOT EXISTS idx_grades_student_id ON grades(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_semester_id ON grades(semester_id);

-- =====================================================
-- 3. CREATE FUNCTIONS
-- =====================================================

-- Function to get current user's school_id
CREATE OR REPLACE FUNCTION get_user_school_id()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_school_id INTEGER;
BEGIN
    SELECT school_id INTO user_school_id
    FROM profiles
    WHERE id = auth.uid();
    
    RETURN user_school_id;
END;
$$;

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT user_type INTO user_role
    FROM profiles
    WHERE id = auth.uid();
    
    RETURN COALESCE(user_role, 'none');
END;
$$;

-- Function to create a new user profile
CREATE OR REPLACE FUNCTION create_user_profile(
    p_user_id UUID,
    p_school_id INTEGER,
    p_user_type TEXT,
    p_name TEXT,
    p_user_identifier TEXT,
    p_phone TEXT DEFAULT NULL,
    p_permissions JSONB DEFAULT '{}',
    p_class_id UUID DEFAULT NULL,
    p_parent_contact TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT NULL -- Should be 'male' or 'female' or NULL for teachers/admins
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate user_type
    IF p_user_type NOT IN ('admin', 'teacher', 'student') THEN
        RAISE EXCEPTION 'Invalid user_type. Must be admin, teacher, or student';
    END IF;
    
    -- Validate required fields based on user_type
    IF p_user_type = 'student' AND (p_class_id IS NULL) THEN
        RAISE EXCEPTION 'Students must have class_id';
    END IF;
    
    -- Validate gender for students
    IF p_user_type = 'student' AND p_gender IS NULL THEN
        RAISE EXCEPTION 'Students must have gender specified';
    END IF;
    
    -- Validate gender values
    IF p_gender IS NOT NULL AND p_gender NOT IN ('male', 'female') THEN
        RAISE EXCEPTION 'Gender must be male or female';
    END IF;
    
    INSERT INTO profiles (
        id, school_id, user_type, name, user_id, phone,
        permissions, class_id, parent_contact, gender
    )
    VALUES (
        p_user_id, p_school_id, p_user_type, p_name, p_user_identifier, p_phone,
        CASE WHEN p_user_type = 'admin' THEN p_permissions ELSE NULL END,
        CASE WHEN p_user_type = 'student' THEN p_class_id ELSE NULL END,
        CASE WHEN p_user_type = 'student' THEN p_parent_contact ELSE NULL END,
        p_gender
    );
    
    RETURN p_user_id;
END;
$$;

-- Function to get user profile with role
CREATE OR REPLACE FUNCTION get_user_profile(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    school_id INTEGER,
    user_type TEXT,
    name TEXT,
    user_id TEXT,
    phone TEXT,
    permissions JSONB,
    class_id UUID,
    parent_contact TEXT,
    gender TEXT,
    school_name TEXT,
    class_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.school_id,
        p.user_type,
        p.name,
        p.user_id,
        p.phone,
        p.permissions,
        p.class_id,
        p.parent_contact,
        p.gender,
        s.name as school_name,
        c.name as class_name
    FROM profiles p
    JOIN schools s ON p.school_id = s.id
    LEFT JOIN classes c ON p.class_id = c.id
    WHERE p.id = p_user_id;
END;
$$;

-- Function to get all users by type and school
CREATE OR REPLACE FUNCTION get_users_by_type(
    p_school_id INTEGER,
    p_user_type TEXT,
    p_limit INTEGER DEFAULT NULL,
    p_offset INTEGER DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    name TEXT,
    user_id TEXT,
    phone TEXT,
    email TEXT,
    class_name TEXT,
    gender TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.user_id,
        p.phone,
        au.email::TEXT, -- Cast VARCHAR(255) to TEXT to fix type mismatch
        c.name as class_name,
        p.gender,
        p.created_at
    FROM profiles p
    JOIN auth.users au ON p.id = au.id
    LEFT JOIN classes c ON p.class_id = c.id
    WHERE p.school_id = p_school_id
    AND p.user_type = p_user_type
    ORDER BY p.name
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Function to create academic year with semesters
CREATE OR REPLACE FUNCTION create_academic_year(
    p_school_id INTEGER,
    p_name TEXT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_year_id UUID;
    semester_duration INTERVAL;
    semester_start DATE;
BEGIN
    -- Insert academic year
    INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
    VALUES (p_school_id, p_name, p_start_date, p_end_date, TRUE)
    RETURNING id INTO new_year_id;
    
    -- Set other years as not current
    UPDATE academic_years 
    SET is_current = FALSE 
    WHERE school_id = p_school_id AND id != new_year_id;
    
    -- Calculate semester duration (divide year into 3 semesters)
    semester_duration := (p_end_date - p_start_date) / 3;
    semester_start := p_start_date;
    
    -- Create 3 semesters
    FOR i IN 1..3 LOOP
        INSERT INTO semesters (
            academic_year_id, 
            name, 
            semester_number, 
            start_date, 
            end_date,
            is_current
        )
        VALUES (
            new_year_id,
            'Semester ' || i,
            i,
            semester_start,
            semester_start + semester_duration,
            CASE WHEN i = 1 THEN TRUE ELSE FALSE END
        );
        
        semester_start := semester_start + semester_duration + INTERVAL '1 day';
    END LOOP;
    
    RETURN new_year_id;
END;
$$;

-- Function to get current semester
CREATE OR REPLACE FUNCTION get_current_semester(p_school_id INTEGER)
RETURNS TABLE(
    semester_id UUID,
    semester_name TEXT,
    semester_number INTEGER,
    academic_year_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.semester_number,
        ay.name
    FROM semesters s
    JOIN academic_years ay ON s.academic_year_id = ay.id
    WHERE ay.school_id = p_school_id 
    AND s.is_current = TRUE
    AND ay.is_current = TRUE;
END;
$$;

-- Function to create timetable entry
CREATE OR REPLACE FUNCTION create_timetable_entry(
    p_school_id INTEGER,
    p_class_id UUID,
    p_subject_id UUID,
    p_teacher_id UUID,
    p_day_of_week TEXT,
    p_start_time TIME,
    p_end_time TIME
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_timetable_id UUID;
    conflict_count INTEGER;
BEGIN
    -- Check for conflicts
    SELECT COUNT(*) INTO conflict_count
    FROM timetables
    WHERE class_id = p_class_id
    AND day_of_week = p_day_of_week
    AND (
        (p_start_time >= start_time AND p_start_time < end_time) OR
        (p_end_time > start_time AND p_end_time <= end_time) OR
        (p_start_time <= start_time AND p_end_time >= end_time)
    );
    
    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Time slot conflict detected for class on %', p_day_of_week;
    END IF;
    
    -- Check teacher availability
    SELECT COUNT(*) INTO conflict_count
    FROM timetables
    WHERE teacher_id = p_teacher_id
    AND day_of_week = p_day_of_week
    AND (
        (p_start_time >= start_time AND p_start_time < end_time) OR
        (p_end_time > start_time AND p_end_time <= end_time) OR
        (p_start_time <= start_time AND p_end_time >= end_time)
    );
    
    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Teacher is not available at this time on %', p_day_of_week;
    END IF;
    
    INSERT INTO timetables (school_id, class_id, subject_id, teacher_id, day_of_week, start_time, end_time)
    VALUES (p_school_id, p_class_id, p_subject_id, p_teacher_id, p_day_of_week, p_start_time, p_end_time)
    RETURNING id INTO new_timetable_id;
    
    RETURN new_timetable_id;
END;
-- Function to delete a user profile and all related data
CREATE OR REPLACE FUNCTION delete_user_profile(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_school_id INTEGER;
    user_type_var TEXT;
BEGIN
    -- Get user's school_id and type for validation
    SELECT school_id, user_type INTO user_school_id, user_type_var
    FROM profiles
    WHERE id = p_user_id;
    
    -- Check if user exists
    IF user_school_id IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if current user has permission (is admin of the same school)
    IF get_user_school_id() != user_school_id OR get_user_role() != 'admin' THEN
        RAISE EXCEPTION 'Permission denied. Only admins can delete users from their school.';
    END IF;
    
    -- For teachers, delete related data first
    IF user_type_var = 'teacher' THEN
        -- Delete teacher_subjects entries
        DELETE FROM teacher_subjects WHERE teacher_id = p_user_id;
        
        -- Delete timetable entries
        DELETE FROM timetables WHERE teacher_id = p_user_id;
        
        -- Delete attendance records where this user is the teacher
        DELETE FROM attendance_records WHERE teacher_id = p_user_id;
        
        -- Delete grades where this user is the teacher
        DELETE FROM grades WHERE teacher_id = p_user_id;
    END IF;
    
    -- For students, delete related data
    IF user_type_var = 'student' THEN
        -- Delete attendance records where this user is the student
        DELETE FROM attendance_records WHERE student_id = p_user_id;
        
        -- Delete grades where this user is the student
        DELETE FROM grades WHERE student_id = p_user_id;
    END IF;
    
    -- Delete the profile (auth.users will be handled by CASCADE)
    DELETE FROM profiles WHERE id = p_user_id;
    
    RETURN TRUE;
END;
$$;
$$;

-- Function to mark attendance for multiple students
CREATE OR REPLACE FUNCTION mark_attendance(
    p_teacher_id UUID,
    p_subject_id UUID,
    p_attendance_date DATE,
    p_attendance_data JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    attendance_record JSONB;
    records_count INTEGER := 0;
BEGIN
    FOR attendance_record IN SELECT * FROM jsonb_array_elements(p_attendance_data)
    LOOP
        INSERT INTO attendance_records (
            student_id,
            subject_id,
            teacher_id,
            attendance_date,
            is_present,
            notes
        )
        VALUES (
            (attendance_record->>'student_id')::UUID,
            p_subject_id,
            p_teacher_id,
            p_attendance_date,
            (attendance_record->>'is_present')::BOOLEAN,
            attendance_record->>'notes'
        )
        ON CONFLICT (student_id, subject_id, attendance_date)
        DO UPDATE SET
            is_present = EXCLUDED.is_present,
            notes = EXCLUDED.notes;
        
        records_count := records_count + 1;
    END LOOP;
    
    RETURN records_count;
END;
$$;

-- Function to record grade
CREATE OR REPLACE FUNCTION record_grade(
    p_student_id UUID,
    p_subject_id UUID,
    p_teacher_id UUID,
    p_semester_id UUID,
    p_grade_number INTEGER,
    p_grade_value DECIMAL,
    p_max_grade DECIMAL DEFAULT 100.00,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_grade_id UUID;
BEGIN
    -- Validate grade number (1 or 2)
    IF p_grade_number NOT IN (1, 2) THEN
        RAISE EXCEPTION 'Grade number must be 1 or 2';
    END IF;
    
    -- Validate grade value
    IF p_grade_value < 0 OR p_grade_value > p_max_grade THEN
        RAISE EXCEPTION 'Grade value must be between 0 and %', p_max_grade;
    END IF;
    
    INSERT INTO grades (
        student_id,
        subject_id,
        teacher_id,
        semester_id,
        grade_number,
        grade_value,
        max_grade,
        notes
    )
    VALUES (
        p_student_id,
        p_subject_id,
        p_teacher_id,
        p_semester_id,
        p_grade_number,
        p_grade_value,
        p_max_grade,
        p_notes
    )
    ON CONFLICT (student_id, subject_id, semester_id, grade_number)
    DO UPDATE SET
        grade_value = EXCLUDED.grade_value,
        max_grade = EXCLUDED.max_grade,
        notes = EXCLUDED.notes,
        updated_at = NOW()
    RETURNING id INTO new_grade_id;
    
    RETURN new_grade_id;
END;
$$;

-- =====================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREATE RLS POLICIES
-- =====================================================

-- Schools Policies
DROP POLICY IF EXISTS "Users can view their school" ON schools;
CREATE POLICY "Users can view their school" ON schools
    FOR SELECT USING (id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can update their school" ON schools;
CREATE POLICY "Admins can update their school" ON schools
    FOR UPDATE USING (
        id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Admins can view school profiles" ON profiles;
CREATE POLICY "Admins can view school profiles" ON profiles
    FOR SELECT USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

DROP POLICY IF EXISTS "Admins can create profiles" ON profiles;
CREATE POLICY "Admins can create profiles" ON profiles
    FOR INSERT WITH CHECK (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

DROP POLICY IF EXISTS "Admins can update school profiles" ON profiles;
CREATE POLICY "Admins can update school profiles" ON profiles
    FOR UPDATE USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

DROP POLICY IF EXISTS "Teachers can view school users" ON profiles;
CREATE POLICY "Teachers can view school users" ON profiles
    FOR SELECT USING (
        school_id = get_user_school_id() AND
        get_user_role() = 'teacher' AND
        profiles.user_type IN ('teacher', 'student')
    );

-- Classes Policies
DROP POLICY IF EXISTS "School users can view classes" ON classes;
CREATE POLICY "School users can view classes" ON classes
    FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage classes" ON classes;
CREATE POLICY "Admins can manage classes" ON classes
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Subjects Policies
DROP POLICY IF EXISTS "School users can view subjects" ON subjects;
CREATE POLICY "School users can view subjects" ON subjects
    FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage subjects" ON subjects;
CREATE POLICY "Admins can manage subjects" ON subjects
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Teacher Subjects Policies
DROP POLICY IF EXISTS "School users can view teacher subjects" ON teacher_subjects;
CREATE POLICY "School users can view teacher subjects" ON teacher_subjects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_subjects.teacher_id 
            AND school_id = get_user_school_id()
        )
    );

DROP POLICY IF EXISTS "Admins can manage teacher subjects" ON teacher_subjects;
CREATE POLICY "Admins can manage teacher subjects" ON teacher_subjects
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_subjects.teacher_id 
            AND school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );

-- Academic Years Policies
DROP POLICY IF EXISTS "School users can view academic years" ON academic_years;
CREATE POLICY "School users can view academic years" ON academic_years
    FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage academic years" ON academic_years;
CREATE POLICY "Admins can manage academic years" ON academic_years
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Semesters Policies
DROP POLICY IF EXISTS "School users can view semesters" ON semesters;
CREATE POLICY "School users can view semesters" ON semesters
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM academic_years 
            WHERE id = semesters.academic_year_id 
            AND school_id = get_user_school_id()
        )
    );

DROP POLICY IF EXISTS "Admins can manage semesters" ON semesters;
CREATE POLICY "Admins can manage semesters" ON semesters
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM academic_years 
            WHERE id = semesters.academic_year_id 
            AND school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );

-- Timetables Policies
DROP POLICY IF EXISTS "School users can view timetables" ON timetables;
CREATE POLICY "School users can view timetables" ON timetables
    FOR SELECT USING (school_id = get_user_school_id());

DROP POLICY IF EXISTS "Admins can manage timetables" ON timetables;
CREATE POLICY "Admins can manage timetables" ON timetables
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Attendance Policies
DROP POLICY IF EXISTS "Teachers can manage attendance" ON attendance_records;
CREATE POLICY "Teachers can manage attendance" ON attendance_records
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = attendance_records.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'teacher'
    );

DROP POLICY IF EXISTS "Students can view own attendance" ON attendance_records;
CREATE POLICY "Students can view own attendance" ON attendance_records
    FOR SELECT USING (
        student_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = attendance_records.student_id 
            AND s.school_id = get_user_school_id()
        )
    );

DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance_records;
CREATE POLICY "Admins can view all attendance" ON attendance_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = attendance_records.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );

-- Grades Policies
DROP POLICY IF EXISTS "Teachers can manage grades" ON grades;
CREATE POLICY "Teachers can manage grades" ON grades
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = grades.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'teacher'
    );

DROP POLICY IF EXISTS "Students can view own grades" ON grades;
CREATE POLICY "Students can view own grades" ON grades
    FOR SELECT USING (
        student_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = grades.student_id 
            AND s.school_id = get_user_school_id()
        )
    );

DROP POLICY IF EXISTS "Admins can view all grades" ON grades;
CREATE POLICY "Admins can view all grades" ON grades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles s 
            WHERE s.id = grades.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );

-- =====================================================
-- 6. CREATE TRIGGERS
-- =====================================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to relevant tables
DROP TRIGGER IF EXISTS update_schools_updated_at ON schools;
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_classes_updated_at ON classes;
CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subjects_updated_at ON subjects;
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_timetables_updated_at ON timetables;
CREATE TRIGGER update_timetables_updated_at BEFORE UPDATE ON timetables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_grades_updated_at ON grades;
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. SAMPLE DATA (OPTIONAL - UNCOMMENT TO USE)
-- =====================================================

/*
-- Insert sample school
INSERT INTO schools (name, address, phone, email) 
VALUES ('Smart Safe School', '123 Education Street', '+1234567890', 'admin@smartsafeschool.com')
ON CONFLICT DO NOTHING;

-- Note: After creating the school, you need to:
-- 1. Create an admin user in Supabase Auth dashboard
-- 2. Insert the admin profile manually with the auth user UUID
-- 
-- Example:
-- INSERT INTO profiles (id, school_id, user_type, name, user_id, permissions)
-- VALUES (
--     'your-auth-user-uuid-here',
--     1,
--     'admin',
--     'School Administrator',
--     'ADM001',
--     '{"manage_users": true, "manage_classes": true, "manage_timetable": true}'::jsonb
-- );
*/

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- 
-- Next Steps:
-- 1. Create your school record in the schools table
-- 2. Create admin user in Supabase Auth dashboard  
-- 3. Create admin profile linking to the auth user
-- 4. Update Flutter app with your Supabase credentials
-- 5. Run the Flutter app and login as admin
-- 
-- =====================================================
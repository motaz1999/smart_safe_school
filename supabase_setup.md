# Supabase Database Setup Guide

## 1. Database Functions

### User Management Functions

```sql
-- Function to create a new admin user
CREATE OR REPLACE FUNCTION create_admin_user(
    p_school_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_admin_id TEXT,
    p_phone TEXT DEFAULT NULL,
    p_permissions JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_admin_id UUID;
BEGIN
    INSERT INTO admins (school_id, name, email, admin_id, phone, permissions)
    VALUES (p_school_id, p_name, p_email, p_admin_id, p_phone, p_permissions)
    RETURNING id INTO new_admin_id;
    
    RETURN new_admin_id;
END;
$$;

-- Function to create a new teacher
CREATE OR REPLACE FUNCTION create_teacher(
    p_school_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_teacher_id TEXT,
    p_phone TEXT DEFAULT NULL,
    p_subject_ids UUID[] DEFAULT ARRAY[]::UUID[]
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_teacher_id UUID;
    subject_id UUID;
BEGIN
    -- Insert teacher
    INSERT INTO teachers (school_id, name, email, teacher_id, phone)
    VALUES (p_school_id, p_name, p_email, p_teacher_id, p_phone)
    RETURNING id INTO new_teacher_id;
    
    -- Assign subjects to teacher
    FOREACH subject_id IN ARRAY p_subject_ids
    LOOP
        INSERT INTO teacher_subjects (teacher_id, subject_id)
        VALUES (new_teacher_id, subject_id)
        ON CONFLICT (teacher_id, subject_id) DO NOTHING;
    END LOOP;
    
    RETURN new_teacher_id;
END;
$$;

-- Function to create a new student
CREATE OR REPLACE FUNCTION create_student(
    p_school_id UUID,
    p_class_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_student_id TEXT,
    p_parent_contact TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_student_id UUID;
BEGIN
    INSERT INTO students (school_id, class_id, name, email, student_id, parent_contact)
    VALUES (p_school_id, p_class_id, p_name, p_email, p_student_id, p_parent_contact)
    RETURNING id INTO new_student_id;
    
    RETURN new_student_id;
END;
$$;
```

### Academic Management Functions

```sql
-- Function to create academic year with semesters
CREATE OR REPLACE FUNCTION create_academic_year(
    p_school_id UUID,
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
CREATE OR REPLACE FUNCTION get_current_semester(p_school_id UUID)
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
```

### Timetable Management Functions

```sql
-- Function to create timetable entry
CREATE OR REPLACE FUNCTION create_timetable_entry(
    p_school_id UUID,
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
$$;

-- Function to get timetable for a class
CREATE OR REPLACE FUNCTION get_class_timetable(p_class_id UUID)
RETURNS TABLE(
    day_of_week TEXT,
    start_time TIME,
    end_time TIME,
    subject_name TEXT,
    subject_code TEXT,
    teacher_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.day_of_week,
        t.start_time,
        t.end_time,
        s.name,
        s.code,
        te.name
    FROM timetables t
    JOIN subjects s ON t.subject_id = s.id
    JOIN teachers te ON t.teacher_id = te.id
    WHERE t.class_id = p_class_id
    ORDER BY 
        CASE t.day_of_week
            WHEN 'monday' THEN 1
            WHEN 'tuesday' THEN 2
            WHEN 'wednesday' THEN 3
            WHEN 'thursday' THEN 4
            WHEN 'friday' THEN 5
            WHEN 'saturday' THEN 6
            WHEN 'sunday' THEN 7
        END,
        t.start_time;
END;
$$;
```

### Attendance Management Functions

```sql
-- Function to mark attendance for multiple students
CREATE OR REPLACE FUNCTION mark_attendance(
    p_teacher_id UUID,
    p_subject_id UUID,
    p_attendance_date DATE,
    p_attendance_data JSONB -- Format: [{"student_id": "uuid", "is_present": true, "notes": ""}]
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

-- Function to get attendance report for a student
CREATE OR REPLACE FUNCTION get_student_attendance(
    p_student_id UUID,
    p_subject_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE(
    subject_name TEXT,
    attendance_date DATE,
    is_present BOOLEAN,
    teacher_name TEXT,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name,
        ar.attendance_date,
        ar.is_present,
        t.name,
        ar.notes
    FROM attendance_records ar
    JOIN subjects s ON ar.subject_id = s.id
    JOIN teachers t ON ar.teacher_id = t.id
    WHERE ar.student_id = p_student_id
    AND (p_subject_id IS NULL OR ar.subject_id = p_subject_id)
    AND (p_start_date IS NULL OR ar.attendance_date >= p_start_date)
    AND (p_end_date IS NULL OR ar.attendance_date <= p_end_date)
    ORDER BY ar.attendance_date DESC, s.name;
END;
$$;
```

### Grading Functions

```sql
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

-- Function to get student grades
CREATE OR REPLACE FUNCTION get_student_grades(
    p_student_id UUID,
    p_semester_id UUID DEFAULT NULL
)
RETURNS TABLE(
    subject_name TEXT,
    subject_code TEXT,
    semester_name TEXT,
    grade_number INTEGER,
    grade_value DECIMAL,
    max_grade DECIMAL,
    percentage DECIMAL,
    teacher_name TEXT,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name,
        s.code,
        sem.name,
        g.grade_number,
        g.grade_value,
        g.max_grade,
        ROUND((g.grade_value / g.max_grade * 100), 2),
        t.name,
        g.notes
    FROM grades g
    JOIN subjects s ON g.subject_id = s.id
    JOIN teachers t ON g.teacher_id = t.id
    JOIN semesters sem ON g.semester_id = sem.id
    WHERE g.student_id = p_student_id
    AND (p_semester_id IS NULL OR g.semester_id = p_semester_id)
    ORDER BY sem.semester_number, s.name, g.grade_number;
END;
$$;

-- Function to calculate semester average
CREATE OR REPLACE FUNCTION get_semester_average(
    p_student_id UUID,
    p_semester_id UUID
)
RETURNS TABLE(
    subject_name TEXT,
    average_grade DECIMAL,
    average_percentage DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name,
        ROUND(AVG(g.grade_value), 2),
        ROUND(AVG(g.grade_value / g.max_grade * 100), 2)
    FROM grades g
    JOIN subjects s ON g.subject_id = s.id
    WHERE g.student_id = p_student_id
    AND g.semester_id = p_semester_id
    GROUP BY s.id, s.name
    ORDER BY s.name;
END;
$$;
```

## 2. Row Level Security (RLS) Policies

### Enable RLS on all tables

```sql
-- Enable RLS on all tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
```

### Helper function to get user's school_id

```sql
-- Function to get current user's school_id based on their role
CREATE OR REPLACE FUNCTION get_user_school_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_school_id UUID;
    user_email TEXT;
BEGIN
    user_email := auth.email();
    
    -- Check if user is an admin
    SELECT school_id INTO user_school_id
    FROM admins
    WHERE email = user_email;
    
    IF user_school_id IS NOT NULL THEN
        RETURN user_school_id;
    END IF;
    
    -- Check if user is a teacher
    SELECT school_id INTO user_school_id
    FROM teachers
    WHERE email = user_email;
    
    IF user_school_id IS NOT NULL THEN
        RETURN user_school_id;
    END IF;
    
    -- Check if user is a student
    SELECT school_id INTO user_school_id
    FROM students
    WHERE email = user_email;
    
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
    user_email TEXT;
    role_count INTEGER;
BEGIN
    user_email := auth.email();
    
    -- Check if user is an admin
    SELECT COUNT(*) INTO role_count FROM admins WHERE email = user_email;
    IF role_count > 0 THEN RETURN 'admin'; END IF;
    
    -- Check if user is a teacher
    SELECT COUNT(*) INTO role_count FROM teachers WHERE email = user_email;
    IF role_count > 0 THEN RETURN 'teacher'; END IF;
    
    -- Check if user is a student
    SELECT COUNT(*) INTO role_count FROM students WHERE email = user_email;
    IF role_count > 0 THEN RETURN 'student'; END IF;
    
    RETURN 'none';
END;
$$;
```

### RLS Policies for Schools table

```sql
-- Schools: Only users belonging to the school can see it
CREATE POLICY "Users can view their school" ON schools
    FOR SELECT USING (id = get_user_school_id());

-- Schools: Only admins can update their school
CREATE POLICY "Admins can update their school" ON schools
    FOR UPDATE USING (
        id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );
```

### RLS Policies for Admins table

```sql
-- Admins: Can view other admins in same school
CREATE POLICY "Admins can view admins in same school" ON admins
    FOR SELECT USING (school_id = get_user_school_id());

-- Admins: Can insert new admins in same school
CREATE POLICY "Admins can create admins in same school" ON admins
    FOR INSERT WITH CHECK (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Admins: Can update admins in same school
CREATE POLICY "Admins can update admins in same school" ON admins
    FOR UPDATE USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );
```

### RLS Policies for Teachers table

```sql
-- Teachers: Can be viewed by admins and other teachers in same school
CREATE POLICY "School users can view teachers" ON teachers
    FOR SELECT USING (school_id = get_user_school_id());

-- Teachers: Can be managed by admins
CREATE POLICY "Admins can manage teachers" ON teachers
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Teachers: Can update their own profile
CREATE POLICY "Teachers can update own profile" ON teachers
    FOR UPDATE USING (
        school_id = get_user_school_id() AND 
        email = auth.email()
    );
```

### RLS Policies for Students table

```sql
-- Students: Can be viewed by school staff and themselves
CREATE POLICY "School users can view students" ON students
    FOR SELECT USING (
        school_id = get_user_school_id() AND
        (get_user_role() IN ('admin', 'teacher') OR email = auth.email())
    );

-- Students: Can be managed by admins
CREATE POLICY "Admins can manage students" ON students
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Students: Can update their own profile (limited fields)
CREATE POLICY "Students can update own profile" ON students
    FOR UPDATE USING (
        school_id = get_user_school_id() AND 
        email = auth.email()
    );
```

### RLS Policies for other tables

```sql
-- Classes: School-based access
CREATE POLICY "School users can view classes" ON classes
    FOR SELECT USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage classes" ON classes
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Subjects: School-based access
CREATE POLICY "School users can view subjects" ON subjects
    FOR SELECT USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage subjects" ON subjects
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Timetables: School-based access
CREATE POLICY "School users can view timetables" ON timetables
    FOR SELECT USING (school_id = get_user_school_id());

CREATE POLICY "Admins can manage timetables" ON timetables
    FOR ALL USING (
        school_id = get_user_school_id() AND 
        get_user_role() = 'admin'
    );

-- Attendance: Teachers can manage, students can view their own
CREATE POLICY "Teachers can manage attendance" ON attendance_records
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = attendance_records.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'teacher'
    );

CREATE POLICY "Students can view own attendance" ON attendance_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = attendance_records.student_id 
            AND s.email = auth.email()
        )
    );

CREATE POLICY "Admins can view all attendance" ON attendance_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = attendance_records.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );

-- Grades: Similar to attendance
CREATE POLICY "Teachers can manage grades" ON grades
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = grades.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'teacher'
    );

CREATE POLICY "Students can view own grades" ON grades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = grades.student_id 
            AND s.email = auth.email()
        )
    );

CREATE POLICY "Admins can view all grades" ON grades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM students s 
            WHERE s.id = grades.student_id 
            AND s.school_id = get_user_school_id()
        ) AND get_user_role() = 'admin'
    );
```

## 3. Initial Setup Script

```sql
-- Create indexes for better performance
CREATE INDEX idx_admins_school_id ON admins(school_id);
CREATE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_teachers_school_id ON teachers(school_id);
CREATE INDEX idx_teachers_email ON teachers(email);
CREATE INDEX idx_students_school_id ON students(school_id);
CREATE INDEX idx_students_class_id ON students(class_id);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_classes_school_id ON classes(school_id);
CREATE INDEX idx_subjects_school_id ON subjects(school_id);
CREATE INDEX idx_timetables_class_id ON timetables(class_id);
CREATE INDEX idx_timetables_teacher_id ON timetables(teacher_id);
CREATE INDEX idx_attendance_student_id ON attendance_records(student_id);
CREATE INDEX idx_attendance_date ON attendance_records(attendance_date);
CREATE INDEX idx_grades_student_id ON grades(student_id);
CREATE INDEX idx_grades_semester_id ON grades(semester_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to relevant tables
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timetables_updated_at BEFORE UPDATE ON timetables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 4. Authentication Setup

### Custom Claims for User Roles

In your Supabase dashboard, you'll need to set up custom claims to handle user roles. Here's the approach:

1. **Create a trigger function to set user metadata:**

```sql
-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_school_id UUID;
BEGIN
    -- Determine user role based on email existence in our tables
    IF EXISTS (SELECT 1 FROM admins WHERE email = NEW.email) THEN
        user_role := 'admin';
        SELECT school_id INTO user_school_id FROM admins WHERE email = NEW.email;
    ELSIF EXISTS (SELECT 1 FROM teachers WHERE email = NEW.email) THEN
        user_role := 'teacher';
        SELECT school_id INTO user_school_id FROM teachers WHERE email = NEW.email;
    ELSIF EXISTS (SELECT 1 FROM students WHERE email = NEW.email) THEN
        user_role := 'student';
        SELECT school_id INTO user_school_id FROM students WHERE email = NEW.email;
    ELSE
        user_role := 'none';
    END IF;
    
    -- Update user metadata
    UPDATE auth.users
    SET raw_app_meta_data = raw_app_meta_data || 
        json_build_object('role', user_role, 'school_id', user_school_id)::jsonb
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## Next Steps

1. Run the database schema creation script in your Supabase SQL editor
2. Execute the functions and RLS policies
3. Set up the authentication triggers
4. Create your first school and admin user through the Supabase dashboard
5. Test the functions and policies
6. Begin Flutter app development

This setup provides a complete, secure, and scalable foundation for your school management system.
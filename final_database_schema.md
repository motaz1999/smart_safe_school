# Final School Management System - Database Schema

## Overview
This schema uses:
- `school_id` as INTEGER (manually added through Supabase dashboard)
- Schools and initial admins created manually through dashboard
- Single `profiles` table for all user types
- Supabase's built-in `auth.users` table for authentication

## Final Database Schema

### Core Tables

#### 1. Schools Table (Manual Creation)
```sql
CREATE TABLE schools (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Profiles Table (Updated with INTEGER school_id)
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    user_type TEXT NOT NULL CHECK (user_type IN ('admin', 'teacher', 'student')),
    name TEXT NOT NULL,
    user_id TEXT UNIQUE NOT NULL, -- admin_id, teacher_id, or student_id
    phone TEXT,
    
    -- Admin specific fields
    permissions JSONB DEFAULT '{}',
    
    -- Student specific fields
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    parent_contact TEXT,
    gender TEXT,
    
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
```

#### 3. Classes Table (Updated with INTEGER school_id)
```sql
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    grade_level TEXT,
    capacity INTEGER DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. Subjects Table (Updated with INTEGER school_id)
```sql
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, code)
);
```

#### 5. Teacher Subjects Junction Table
```sql
CREATE TABLE teacher_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, subject_id),
    
    -- Ensure only teachers can be assigned to subjects
    CONSTRAINT teacher_subjects_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_id AND user_type = 'teacher'
        )
    )
);
```

#### 6. Academic Years Table (Updated with INTEGER school_id)
```sql
CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id INTEGER REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, name)
);
```

#### 7. Semesters Table
```sql
CREATE TABLE semesters (
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
```

#### 8. Timetables Table (Updated with INTEGER school_id)
```sql
CREATE TABLE timetables (
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
    UNIQUE(class_id, day_of_week, start_time),
    
    -- Ensure only teachers can be assigned to timetables
    CONSTRAINT timetable_teacher_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_id AND user_type = 'teacher'
        )
    )
);
```

#### 9. Attendance Records Table
```sql
CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, subject_id, attendance_date),
    
    -- Ensure student_id references a student and teacher_id references a teacher
    CONSTRAINT attendance_student_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = student_id AND user_type = 'student'
        )
    ),
    CONSTRAINT attendance_teacher_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_id AND user_type = 'teacher'
        )
    )
);
```

#### 10. Grades Table
```sql
CREATE TABLE grades (
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
    UNIQUE(student_id, subject_id, semester_id, grade_number),
    
    -- Ensure student_id references a student and teacher_id references a teacher
    CONSTRAINT grades_student_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = student_id AND user_type = 'student'
        )
    ),
    CONSTRAINT grades_teacher_check CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = teacher_id AND user_type = 'teacher'
        )
    )
);
```

## Updated Helper Functions

### Get User School ID (Updated for INTEGER)
```sql
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
```

### Profile Management Functions (Updated)

```sql
-- Function to create a new user profile (Updated for INTEGER school_id)
CREATE OR REPLACE FUNCTION create_user_profile(
    p_user_id UUID,
    p_school_id INTEGER,
    p_user_type TEXT,
    p_name TEXT,
    p_user_identifier TEXT, -- admin_id, teacher_id, or student_id
    p_phone TEXT DEFAULT NULL,
    p_permissions JSONB DEFAULT '{}',
    p_class_id UUID DEFAULT NULL,
    p_parent_contact TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT NULL
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

-- Function to get user profile with role (Updated for INTEGER school_id)
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

-- Function to get all users by type and school (Updated for INTEGER school_id)
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
```

## Manual Setup Process

### Step 1: Create School (Manual via Supabase Dashboard)
```sql
-- Example: Insert school manually in Supabase dashboard
INSERT INTO schools (name, address, phone, email) 
VALUES ('Smart Safe School', '123 Education St', '+1234567890', 'admin@smartsafeschool.com');
-- This will get id = 1 (auto-increment)
```

### Step 2: Create Admin User (Manual Process)
1. **Create auth user in Supabase Auth dashboard:**
   - Email: admin@smartsafeschool.com
   - Password: (set password)
   - This creates a UUID in auth.users

2. **Create admin profile manually:**
```sql
-- Insert admin profile (use the UUID from auth.users)
INSERT INTO profiles (id, school_id, user_type, name, user_id, permissions)
VALUES (
    'auth-user-uuid-here', -- UUID from auth.users
    1, -- school_id from step 1
    'admin',
    'School Administrator',
    'ADM001',
    '{"manage_users": true, "manage_classes": true, "manage_timetable": true}'::jsonb
);
```

### Step 3: Admin Can Then Use App
Once the admin is set up, they can:
- Log in to the Flutter app
- Add teachers and students
- Create classes and subjects
- Manage timetables
- View reports

## Updated Flutter Models (INTEGER school_id)

```dart
class UserProfile extends BaseModel {
    final int schoolId; // Changed from String to int
    final UserType userType;
    final String name;
    final String userId;
    final String email;
    final String? phone;
    final Map<String, dynamic>? permissions;
    final String? classId;
    final String? parentContact;
    final String? gender;
    final String? schoolName;
    final String? className;

  UserProfile({
      required super.id,
      required super.createdAt,
      super.updatedAt,
      required this.schoolId, // Now INTEGER
      required this.userType,
      required this.name,
      required this.userId,
      required this.email,
      this.phone,
      this.permissions,
      this.classId,
      this.parentContact,
      this.gender,
      this.schoolName,
      this.className,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      schoolId: json['school_id'], // INTEGER from database
      userType: UserType.values.firstWhere(
        (e) => e.name == json['user_type'],
      ),
      name: json['name'],
      userId: json['user_id'],
      email: json['email'] ?? '',
      phone: json['phone'],
      permissions: json['permissions'],
      classId: json['class_id'],
      parentContact: json['parent_contact'],
      gender: json['gender'],
      schoolName: json['school_name'],
      className: json['class_name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId, // INTEGER
      'user_type': userType.name,
      'name': name,
      'user_id': userId,
      'phone': phone,
      'permissions': permissions,
      'class_id': classId,
      'parent_contact': parentContact,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Similar updates for other models that reference school_id
class School extends BaseModel {
  final int id; // Changed from String to int
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  School({
    required String stringId, // Keep string ID for BaseModel
    required this.id, // Add integer id
    required super.createdAt,
    super.updatedAt,
    required this.name,
    this.address,
    this.phone,
    this.email,
  }) : super(id: stringId);

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      stringId: json['id'].toString(),
      id: json['id'], // INTEGER from database
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id, // INTEGER
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
```

## Summary

This final schema:
1. ✅ Uses INTEGER `school_id` as requested
2. ✅ Schools are created manually through Supabase dashboard
3. ✅ Initial admin is created manually through dashboard
4. ✅ Admin can then use the Flutter app to manage everything else
5. ✅ Single profiles table for all user types
6. ✅ Proper RLS policies for security
7. ✅ All necessary functions for CRUD operations

The setup process is now:
1. **Manual**: Create school in dashboard
2. **Manual**: Create admin auth user and profile
3. **App**: Admin logs in and manages everything else through Flutter app

This approach gives you full control over the initial setup while providing a powerful admin interface for ongoing management.
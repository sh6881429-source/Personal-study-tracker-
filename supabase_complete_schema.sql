-- ── PREPTRACKER BY YASH: COMPLETE DATABASE SCHEMA ──
-- Highly optimized, secure, and production-ready PostgreSQL setup for Supabase.

-- ────────────────────────────────────────────────────────────────
-- 1. EXTENSIONS & STORAGE BUCKET SEEDING SETUP
-- ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────────
-- 2. TABLE DEFINITIONS
-- ────────────────────────────────────────────────────────────────

-- 1. profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. subjects
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_name TEXT NOT NULL,
    description TEXT,
    color TEXT NOT NULL, -- Hex code representation e.g. "#FFD60A"
    icon TEXT NOT NULL, -- Identifier for icon e.g. "book", "fitness"
    display_order INTEGER DEFAULT 0 NOT NULL,
    is_archived BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_subject UNIQUE(user_id, subject_name)
);

-- 3. chapters
CREATE TABLE IF NOT EXISTS public.chapters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    chapter_name TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT false NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    target_revisions INTEGER DEFAULT 1 NOT NULL,
    current_revisions INTEGER DEFAULT 0 NOT NULL,
    display_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_revisions CHECK (current_revisions >= 0 AND target_revisions >= 0)
);

-- 4. study_sessions
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL,
    session_notes TEXT,
    session_type TEXT DEFAULT 'Normal Study' NOT NULL,
    study_date DATE DEFAULT CURRENT_DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_session_duration CHECK (duration_minutes >= 0),
    CONSTRAINT chk_session_times CHECK (end_time >= start_time)
);

-- 5. bookmarks
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT DEFAULT 'Medium' NOT NULL, -- Low, Medium, High
    is_completed BOOLEAN DEFAULT false NOT NULL,
    is_pinned BOOLEAN DEFAULT false NOT NULL,
    reminder_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_priority CHECK (priority IN ('Low', 'Medium', 'High'))
);

-- 6. pdf_library
CREATE TABLE IF NOT EXISTS public.pdf_library (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    original_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size INTEGER NOT NULL, -- Size in bytes
    page_count INTEGER,
    is_favorite BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_file_size CHECK (file_size > 0)
);

-- 7. gym_attendance
CREATE TABLE IF NOT EXISTS public.gym_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    status TEXT NOT NULL, -- Present, Absent, Rest Day
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_attendance_date UNIQUE (user_id, attendance_date),
    CONSTRAINT chk_status CHECK (status IN ('Present', 'Absent', 'Rest Day'))
);

-- 8. daily_goals
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    study_goal_minutes INTEGER DEFAULT 120 NOT NULL,
    target_chapters INTEGER DEFAULT 1 NOT NULL,
    target_revisions INTEGER DEFAULT 1 NOT NULL,
    water_goal INTEGER DEFAULT 8 NOT NULL, -- in glasses/cups
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_goals CHECK (study_goal_minutes >= 0 AND target_chapters >= 0 AND target_revisions >= 0 AND water_goal >= 0)
);

-- 9. user_settings
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_mode TEXT DEFAULT 'system' NOT NULL, -- light, dark, system
    notification_enabled BOOLEAN DEFAULT true NOT NULL,
    study_reminder_time TEXT DEFAULT '09:00' NOT NULL, -- Format: HH:MM
    gym_reminder_time TEXT DEFAULT '17:00' NOT NULL, -- Format: HH:MM
    default_revision_target INTEGER DEFAULT 3 NOT NULL,
    language TEXT DEFAULT 'en' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_theme CHECK (theme_mode IN ('light', 'dark', 'system'))
);

-- 10. exams
CREATE TABLE IF NOT EXISTS public.exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_name TEXT NOT NULL,
    exam_date TIMESTAMP WITH TIME ZONE NOT NULL,
    target_score TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. ai_chat_history
CREATE TABLE IF NOT EXISTS public.ai_chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 12. achievements
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_name TEXT NOT NULL,
    description TEXT NOT NULL,
    earned BOOLEAN DEFAULT false NOT NULL,
    earned_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_name)
);

-- ────────────────────────────────────────────────────────────────
-- 3. INDEXES FOR DASHBOARD QUERY OPTIMIZATION
-- ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_chapters_subject ON public.chapters(subject_id);
CREATE INDEX IF NOT EXISTS idx_chapters_user ON public.chapters(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_date ON public.study_sessions(user_id, study_date);
CREATE INDEX IF NOT EXISTS idx_study_sessions_subject ON public.study_sessions(subject_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_pdf_library_user ON public.pdf_library(user_id);
CREATE INDEX IF NOT EXISTS idx_gym_attendance_user_date ON public.gym_attendance(user_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_exams_user_date ON public.exams(user_id, exam_date);
CREATE INDEX IF NOT EXISTS idx_chat_history_user_created ON public.ai_chat_history(user_id, created_at DESC);

-- ────────────────────────────────────────────────────────────────
-- 4. DATABASE TRIGGERS AND FUNCTIONS
-- ────────────────────────────────────────────────────────────────

-- 1. Automatic updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind trigger to every table
CREATE TRIGGER trigger_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_subjects_updated_at BEFORE UPDATE ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_chapters_updated_at BEFORE UPDATE ON public.chapters FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_study_sessions_updated_at BEFORE UPDATE ON public.study_sessions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_bookmarks_updated_at BEFORE UPDATE ON public.bookmarks FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_pdf_library_updated_at BEFORE UPDATE ON public.pdf_library FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_gym_attendance_updated_at BEFORE UPDATE ON public.gym_attendance FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_daily_goals_updated_at BEFORE UPDATE ON public.daily_goals FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_exams_updated_at BEFORE UPDATE ON public.exams FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_ai_chat_history_updated_at BEFORE UPDATE ON public.ai_chat_history FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trigger_achievements_updated_at BEFORE UPDATE ON public.achievements FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 2. Safe delete user profile (and cascading data cleanup) function
CREATE OR REPLACE FUNCTION public.delete_user_data(user_id_param UUID)
RETURNS VOID AS $$
BEGIN
    -- Auth.users cascade deletes will handle profiles and related tables,
    -- but this function offers an explicit cleanup option.
    DELETE FROM public.profiles WHERE user_id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Calculate study hours
CREATE OR REPLACE FUNCTION public.calculate_study_hours(
    user_id_param UUID,
    start_date DATE,
    end_date DATE
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    total_minutes INTEGER;
BEGIN
    SELECT COALESCE(SUM(duration_minutes), 0)
    INTO total_minutes
    FROM public.study_sessions
    WHERE user_id = user_id_param
      AND study_date BETWEEN start_date AND end_date;
      
    RETURN total_minutes / 60.0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Calculate study streak
CREATE OR REPLACE FUNCTION public.calculate_study_streak(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
    current_streak INTEGER := 0;
    check_date DATE := CURRENT_DATE;
    has_studied BOOLEAN;
BEGIN
    LOOP
        SELECT EXISTS (
            SELECT 1 
            FROM public.study_sessions 
            WHERE user_id = user_id_param 
              AND study_date = check_date
        ) INTO has_studied;
        
        IF has_studied THEN
            current_streak := current_streak + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSE
            -- Allow today to not be logged yet if they studied yesterday
            IF check_date = CURRENT_DATE THEN
                check_date := check_date - INTERVAL '1 day';
                SELECT EXISTS (
                    SELECT 1 
                    FROM public.study_sessions 
                    WHERE user_id = user_id_param 
                      AND study_date = check_date
                ) INTO has_studied;
                
                IF NOT has_studied THEN
                    EXIT;
                END IF;
            ELSE
                EXIT;
            END IF;
        END IF;
    END LOOP;
    
    RETURN current_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Calculate pending chapters
CREATE OR REPLACE FUNCTION public.calculate_pending_chapters(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
    pending_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO pending_count
    FROM public.chapters
    WHERE user_id = user_id_param 
      AND is_completed = false;
      
    RETURN pending_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Calculate revision progress
CREATE OR REPLACE FUNCTION public.calculate_revision_progress(user_id_param UUID)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    total_target INTEGER;
    total_current INTEGER;
BEGIN
    SELECT COALESCE(SUM(target_revisions), 0), COALESCE(SUM(current_revisions), 0)
    INTO total_target, total_current
    FROM public.chapters
    WHERE user_id = user_id_param;
    
    IF total_target = 0 THEN
        RETURN 0.0;
    END IF;
    
    RETURN (total_current::DOUBLE PRECISION / total_target::DOUBLE PRECISION) * 100.0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Calculate gym attendance percentage
CREATE OR REPLACE FUNCTION public.calculate_gym_attendance_percentage(
    user_id_param UUID,
    start_date DATE,
    end_date DATE
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    total_days INTEGER;
    present_days INTEGER;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'Present')
    INTO total_days, present_days
    FROM public.gym_attendance
    WHERE user_id = user_id_param
      AND attendance_date BETWEEN start_date AND end_date;
      
    IF total_days = 0 THEN
        RETURN 0.0;
    END IF;
    
    RETURN (present_days::DOUBLE PRECISION / total_days::DOUBLE PRECISION) * 100.0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ────────────────────────────────────────────────────────────────
-- 5. ROW LEVEL SECURITY POLICIES FOR EVERY TABLE
-- ────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- 1. profiles policies
CREATE POLICY "Users can manage own profile" ON public.profiles FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. subjects policies
CREATE POLICY "Users can manage own subjects" ON public.subjects FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. chapters policies
CREATE POLICY "Users can manage own chapters" ON public.chapters FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. study_sessions policies
CREATE POLICY "Users can manage own study_sessions" ON public.study_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. bookmarks policies
CREATE POLICY "Users can manage own bookmarks" ON public.bookmarks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. pdf_library policies
CREATE POLICY "Users can manage own pdfs" ON public.pdf_library FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. gym_attendance policies
CREATE POLICY "Users can manage own attendance" ON public.gym_attendance FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. daily_goals policies
CREATE POLICY "Users can manage own goals" ON public.daily_goals FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. user_settings policies
CREATE POLICY "Users can manage own settings" ON public.user_settings FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. exams policies
CREATE POLICY "Users can manage own exams" ON public.exams FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 11. ai_chat_history policies
CREATE POLICY "Users can manage own chat history" ON public.ai_chat_history FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 12. achievements policies
CREATE POLICY "Users can view own achievements" ON public.achievements FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────────
-- 6. STORAGE BUCKET CONFIGURATION & POLICIES
-- ────────────────────────────────────────────────────────────────

-- Insert buckets config
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('study-pdfs', 'study-pdfs', false)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for profile-images
CREATE POLICY "Allow authenticated upload of profile images" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-images' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Allow public read access to profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');

CREATE POLICY "Allow owner to delete profile images" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'profile-images' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

-- RLS Policies for study-pdfs
CREATE POLICY "Allow authenticated upload of study pdfs" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'study-pdfs' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Allow owner read access to study pdfs" ON storage.objects
    FOR SELECT TO authenticated USING (bucket_id = 'study-pdfs' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Allow owner to delete study pdfs" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'study-pdfs' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

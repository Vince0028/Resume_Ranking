-- Supabase SQL Setup for Resume Ranking App
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

-- 1. Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  bio TEXT,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  hobbies TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create resumes table
CREATE TABLE IF NOT EXISTS public.resumes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  resume_data JSONB DEFAULT '{}'::jsonb,
  average_rating DECIMAL(3,2) DEFAULT 0.00,
  total_ratings INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id) -- One resume per user
);

-- 3. Create resume_ratings table
CREATE TABLE IF NOT EXISTS public.resume_ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE NOT NULL,
  rater_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(resume_id, rater_id) -- One rating per user per resume
);

-- 4. Create friendships table (FIXED: now references profiles instead of auth.users)
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  addressee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(requester_id, addressee_id)
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resume_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- 6. Drop existing policies if they exist (for re-running the script)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Resumes are viewable by everyone" ON public.resumes;
DROP POLICY IF EXISTS "Users can insert their own resume" ON public.resumes;
DROP POLICY IF EXISTS "Users can update their own resume" ON public.resumes;
DROP POLICY IF EXISTS "Users can delete their own resume" ON public.resumes;
DROP POLICY IF EXISTS "Ratings are viewable by everyone" ON public.resume_ratings;
DROP POLICY IF EXISTS "Authenticated users can insert ratings" ON public.resume_ratings;
DROP POLICY IF EXISTS "Users can update their own ratings" ON public.resume_ratings;
DROP POLICY IF EXISTS "Users can view their own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can update friendships they're part of" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete their own friend requests" ON public.friendships;

-- 7. Create RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- 8. Create RLS Policies for resumes
CREATE POLICY "Resumes are viewable by everyone"
  ON public.resumes FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own resume"
  ON public.resumes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own resume"
  ON public.resumes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own resume"
  ON public.resumes FOR DELETE
  USING (auth.uid() = user_id);

-- 9. Create RLS Policies for resume_ratings
CREATE POLICY "Ratings are viewable by everyone"
  ON public.resume_ratings FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert ratings"
  ON public.resume_ratings FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "Users can update their own ratings"
  ON public.resume_ratings FOR UPDATE
  USING (auth.uid() = rater_id);

-- 10. Create RLS Policies for friendships
CREATE POLICY "Users can view their own friendships"
  ON public.friendships FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can send friend requests"
  ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update friendships they're part of"
  ON public.friendships FOR UPDATE
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can delete their own friend requests"
  ON public.friendships FOR DELETE
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- 11. Create function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create trigger for auto-creating profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON public.resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resumes_average_rating ON public.resumes(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_resume_ratings_resume_id ON public.resume_ratings(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_ratings_rater_id ON public.resume_ratings(rater_id);
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- ============================================
-- DEFAULT USER SETUP (vince / alobin)
-- ============================================
-- Create the user directly in auth.users and profiles

-- Check if user already exists, if not create them
DO $$
DECLARE
  vince_user_id UUID;
  user_exists BOOLEAN;
BEGIN
  -- Check if user already exists
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'vince@example.com') INTO user_exists;
  
  IF NOT user_exists THEN
    -- Insert the user into auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000'::uuid,
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'vince@example.com',
      crypt('alobin', gen_salt('bf')),
      now(),
      now(),
      '',
      now(),
      '',
      now(),
      '',
      '',
      now(),
      now(),
      '{"provider": "email", "providers": ["email"]}',
      '{"name": "Vince Nelmar Alobin"}',
      false,
      now(),
      now(),
      null,
      null,
      '',
      '',
      now(),
      '',
      0,
      now(),
      '',
      now()
    );
  END IF;

  -- Get the user ID (whether just created or already existed)
  SELECT id INTO vince_user_id FROM auth.users WHERE email = 'vince@example.com';
  
  -- Insert/Update the profile
  INSERT INTO public.profiles (id, name, bio, email, phone, hobbies, created_at, updated_at)
  VALUES (
    vince_user_id,
    'Vince Nelmar Alobin',
    'Full Stack Developer | Mobile App Enthusiast | UI/UX Designer | Open Source Contributor',
    'alobinvince@gmail.com',
    '+63 912 345 6789',
    ARRAY['Flutter', 'React', 'Python', 'UI/UX', 'Open Source', 'Full Stack'],
    now(),
    now()
  ) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    bio = EXCLUDED.bio,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    hobbies = EXCLUDED.hobbies,
    updated_at = now();

  -- Insert/Update the resume (ensuring it's #1 with high rating)
  INSERT INTO public.resumes (user_id, title, content, average_rating, total_ratings, created_at, updated_at)
  VALUES (
    vince_user_id,
    'Full Stack Developer Resume',
    'Full Stack Developer | Mobile App Enthusiast | UI/UX Designer | Open Source Contributor',
    5.0,
    100,
    now(),
    now()
  ) ON CONFLICT (user_id) DO UPDATE SET
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    average_rating = EXCLUDED.average_rating,
    total_ratings = EXCLUDED.total_ratings,
    updated_at = now();

END $$;
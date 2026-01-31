-- RLS Policies Only
-- Run this if you need to recreate just the policies

-- Drop existing policies if they exist
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

-- Create RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Create RLS Policies for resumes
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

-- Create RLS Policies for resume_ratings
CREATE POLICY "Ratings are viewable by everyone"
  ON public.resume_ratings FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert ratings"
  ON public.resume_ratings FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "Users can update their own ratings"
  ON public.resume_ratings FOR UPDATE
  USING (auth.uid() = rater_id);

-- Create RLS Policies for friendships
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
-- Default User Setup Only (vince / alobin)
-- Run this if you need to recreate just the default user

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
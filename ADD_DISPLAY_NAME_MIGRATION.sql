-- Add display_name column to user_profiles table
-- This allows users to set a custom display name instead of using email prefix

ALTER TABLE user_profiles 
ADD COLUMN display_name TEXT;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name 
ON user_profiles(display_name);

-- Set default display name for existing users (first part of email)
UPDATE user_profiles 
SET display_name = SPLIT_PART(email, '@', 1) 
WHERE display_name IS NULL AND email IS NOT NULL;

# Supabase Storage Setup for Profile Pictures

## 1. Create Storage Bucket

Go to your Supabase dashboard → Storage → Create a new bucket

**Bucket Name:** `profile-pics`
**Public:** Yes (checked)
**File size limit:** 5MB
**Allowed MIME types:** `image/jpeg,image/png,image/webp`

## 2. Set Up Storage Policies (SQL Editor)

Run these commands in your Supabase SQL Editor:

```sql
-- Enable RLS (Row Level Security) on the storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to upload their own profile pictures
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-pics' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy to allow users to update their own profile pictures
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-pics' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy to allow users to delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-pics' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy to allow everyone to view profile pictures (since they're public)
CREATE POLICY "Anyone can view profile pictures" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-pics');
```

## 3. Alternative: Create Bucket via SQL

If you prefer to create the bucket via SQL:

```sql
-- Create the profile-pics bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-pics',
  'profile-pics', 
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);
```

## 4. Test the Setup

After setting up:
1. Try uploading a profile picture in your app
2. Check if the image appears in Storage → profile-pics in your dashboard
3. Verify the public URL works by visiting it directly

## Notes

- Profile pictures are stored as `{user_id}/profile.jpg`
- Images are automatically compressed to JPEG format
- The bucket is public, so anyone with the URL can view the images
- Users can only upload/update/delete their own profile pictures

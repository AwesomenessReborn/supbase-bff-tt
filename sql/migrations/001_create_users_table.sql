/*
Scaffolds application-facing user profiles by mirroring Supabase Auth IDs,
capturing contact and role metadata, indexing lookup columns, wiring a trigger
that refreshes audit timestamps, and enforcing row level security boundaries.
*/
-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- CHANGE: explicit link to Supabase Auth system
  supabase_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  email TEXT UNIQUE NOT NULL,
  
  -- Role Management (Text check is flexible and easier to migrate than ENUMs)
  role TEXT NOT NULL DEFAULT 'RUSHEE' CHECK (role IN ('ADMIN', 'ACTIVE', 'PLEDGE', 'RUSHEE')),
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_users_supabase_id ON users(supabase_id);
CREATE INDEX idx_users_email ON users(email);

-- Auto-update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Attach trigger to users table
CREATE TRIGGER update_users_updated_at 
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

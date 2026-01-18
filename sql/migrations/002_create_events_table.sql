/*
Creates events table for rush activities (dinners, smokers, interviews, meetings).
Tracks event metadata, scheduling, capacity, and voting context with indexes for
chronological and type-based queries.
*/

-- Create events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Event Details
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN ('DINNER', 'SMOKER', 'INTERVIEW', 'SOCIAL', 'MEETING', 'OTHER')),

  -- Scheduling
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  location TEXT,

  -- Rush-Specific Flags
  is_mandatory BOOLEAN DEFAULT false,
  is_voting_event BOOLEAN DEFAULT false,
  max_capacity INTEGER,

  -- Metadata
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_created_by ON events(created_by);
CREATE INDEX idx_events_is_active ON events(is_active);

-- Attach update timestamp trigger
CREATE TRIGGER update_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone authenticated can view active events
CREATE POLICY "Authenticated users can view active events"
ON events FOR SELECT
TO authenticated
USING (is_active = true);

-- RLS Policy: Only admins can create/update/delete events
CREATE POLICY "Admins can manage events"
ON events FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

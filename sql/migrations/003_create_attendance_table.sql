/*
Tracks attendance at rush events with check-in details and optional RSVP status.
Enforces unique attendance records per user per event and indexes lookups by
event, user, and status for roster and history queries.
*/

-- Create attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- RSVP (future feature - optional for now)
  rsvp_status TEXT CHECK (rsvp_status IN ('GOING', 'MAYBE', 'NOT_GOING')),

  -- Attendance Details
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PRESENT', 'ABSENT', 'EXCUSED', 'LATE')),
  checked_in_at TIMESTAMPTZ,
  checked_in_by UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Notes
  notes TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate attendance records
  UNIQUE(event_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_attendance_event_id ON attendance(event_id);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_status ON attendance(status);
CREATE INDEX idx_attendance_checked_in_by ON attendance(checked_in_by);

-- Attach update timestamp trigger
CREATE TRIGGER update_attendance_updated_at
BEFORE UPDATE ON attendance
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own attendance
CREATE POLICY "Users can view own attendance"
ON attendance FOR SELECT
TO authenticated
USING (
  user_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can view all attendance
CREATE POLICY "Admins can view all attendance"
ON attendance FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

-- RLS Policy: Only admins can create/update attendance records
CREATE POLICY "Admins can manage attendance"
ON attendance FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

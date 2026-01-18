/*
Captures written feedback and ratings on candidates from active members.
Supports optional anonymity, privacy flags, categorical tags, and event context.
Indexed for efficient candidate feedback aggregation and filtering by rating.
*/

-- Create feedback table
CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Feedback Content
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,

  -- Categories (optional tags)
  tags TEXT[],  -- ['good_fit', 'leadership', 'academic', 'social', etc.]

  -- Visibility Controls
  is_anonymous BOOLEAN DEFAULT false,
  is_private BOOLEAN DEFAULT false,  -- Only visible to admins

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_feedback_author_id ON feedback(author_id);
CREATE INDEX idx_feedback_candidate_id ON feedback(candidate_id);
CREATE INDEX idx_feedback_event_id ON feedback(event_id);
CREATE INDEX idx_feedback_rating ON feedback(rating);
CREATE INDEX idx_feedback_created_at ON feedback(created_at);

-- Attach update timestamp trigger
CREATE TRIGGER update_feedback_updated_at
BEFORE UPDATE ON feedback
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Authors can view their own feedback
CREATE POLICY "Authors can view own feedback"
ON feedback FOR SELECT
TO authenticated
USING (
  author_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can view all feedback (including private)
CREATE POLICY "Admins can view all feedback"
ON feedback FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

-- RLS Policy: Active members can view non-private feedback about candidates
CREATE POLICY "Active members can view public feedback"
ON feedback FOR SELECT
TO authenticated
USING (
  is_private = false
  AND EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role IN ('ACTIVE', 'ADMIN')
    AND users.is_active = true
  )
);

-- RLS Policy: Active members can create feedback
CREATE POLICY "Active members can create feedback"
ON feedback FOR INSERT
TO authenticated
WITH CHECK (
  author_id IN (
    SELECT id FROM users
    WHERE supabase_id = auth.uid()
    AND role IN ('ACTIVE', 'PLEDGE', 'ADMIN')
    AND is_active = true
  )
);

-- RLS Policy: Authors can update their own feedback
CREATE POLICY "Authors can update own feedback"
ON feedback FOR UPDATE
TO authenticated
USING (
  author_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

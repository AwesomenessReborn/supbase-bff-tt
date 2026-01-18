/*
Captures interview content and assessments for candidates during rush.
Links interviewer (active member) with candidate, stores structured interview data,
ratings, and notes. Supports both event-based and standalone interviews with
indexes optimized for candidate profile views and interviewer history.
*/

-- Create interviews table
CREATE TABLE interviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,  -- Optional: if interview happened at an event
  interviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Interview Details
  interview_date TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Interview Content (flexible structure)
  questions_and_answers JSONB,  -- Structured Q&A: [{"question": "...", "answer": "..."}, ...]
  notes TEXT,                    -- Free-form notes from interviewer

  -- Assessment
  overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
  recommendation TEXT CHECK (recommendation IN ('STRONG_BID', 'BID', 'NEUTRAL', 'NO_BID', 'STRONG_NO_BID')),

  -- Key Attributes (tags for filtering)
  strengths TEXT[],   -- ['leadership', 'social', 'academic', etc.]
  concerns TEXT[],    -- ['time_commitment', 'fit', etc.]

  -- Status
  is_complete BOOLEAN DEFAULT true,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_interviews_interviewer_id ON interviews(interviewer_id);
CREATE INDEX idx_interviews_candidate_id ON interviews(candidate_id);
CREATE INDEX idx_interviews_event_id ON interviews(event_id);
CREATE INDEX idx_interviews_interview_date ON interviews(interview_date);
CREATE INDEX idx_interviews_recommendation ON interviews(recommendation);
CREATE INDEX idx_interviews_overall_rating ON interviews(overall_rating);

-- Attach update timestamp trigger
CREATE TRIGGER update_interviews_updated_at
BEFORE UPDATE ON interviews
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Interviewers can view their own interviews
CREATE POLICY "Interviewers can view own interviews"
ON interviews FOR SELECT
TO authenticated
USING (
  interviewer_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can view all interviews
CREATE POLICY "Admins can view all interviews"
ON interviews FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

-- RLS Policy: Active members can view interviews for candidates (aggregated view)
-- This allows showing interview summaries on candidate profiles
CREATE POLICY "Active members can view candidate interviews"
ON interviews FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role IN ('ACTIVE', 'ADMIN')
    AND users.is_active = true
  )
);

-- RLS Policy: Active members can create interviews
CREATE POLICY "Active members can create interviews"
ON interviews FOR INSERT
TO authenticated
WITH CHECK (
  interviewer_id IN (
    SELECT id FROM users
    WHERE supabase_id = auth.uid()
    AND role IN ('ACTIVE', 'ADMIN')
    AND is_active = true
  )
);

-- RLS Policy: Interviewers can update their own interviews
CREATE POLICY "Interviewers can update own interviews"
ON interviews FOR UPDATE
TO authenticated
USING (
  interviewer_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can delete any interview
CREATE POLICY "Admins can delete interviews"
ON interviews FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

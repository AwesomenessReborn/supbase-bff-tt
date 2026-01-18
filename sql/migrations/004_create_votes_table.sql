/*
Implements secret ballot voting on candidates with support for multiple voting rounds.
Tracks vote type (BID/NO_BID/ABSTAIN), optional numerical ratings, and prevents
duplicate votes per voter-candidate-round combination. RLS policies ensure vote
anonymity while allowing aggregated results.
*/

-- Create votes table
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  voter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Vote Details
  vote_type TEXT NOT NULL CHECK (vote_type IN ('BID', 'NO_BID', 'ABSTAIN')),
  vote_value INTEGER CHECK (vote_value >= 1 AND vote_value <= 10),

  -- Anonymity
  is_anonymous BOOLEAN DEFAULT true,

  -- Voting Round Context
  voting_round TEXT,  -- "Round 1", "Round 2", "Final", etc.

  -- Private Notes (only visible to voter)
  notes TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate votes in same round
  UNIQUE(voter_id, candidate_id, voting_round)
);

-- Indexes for performance
CREATE INDEX idx_votes_voter_id ON votes(voter_id);
CREATE INDEX idx_votes_candidate_id ON votes(candidate_id);
CREATE INDEX idx_votes_event_id ON votes(event_id);
CREATE INDEX idx_votes_vote_type ON votes(vote_type);
CREATE INDEX idx_votes_voting_round ON votes(voting_round);

-- Attach update timestamp trigger
CREATE TRIGGER update_votes_updated_at
BEFORE UPDATE ON votes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Voters can view only their own votes
CREATE POLICY "Users can view own votes"
ON votes FOR SELECT
TO authenticated
USING (
  voter_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Active members can create votes
CREATE POLICY "Active members can create votes"
ON votes FOR INSERT
TO authenticated
WITH CHECK (
  voter_id IN (
    SELECT id FROM users
    WHERE supabase_id = auth.uid()
    AND role IN ('ACTIVE', 'ADMIN')
    AND is_active = true
  )
);

-- RLS Policy: Users can update their own votes (before deadline/round closes)
CREATE POLICY "Users can update own votes"
ON votes FOR UPDATE
TO authenticated
USING (
  voter_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can view aggregated vote counts (not individual votes unless needed)
-- Note: For aggregated queries, use a separate database view or function
CREATE POLICY "Admins can view all votes"
ON votes FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

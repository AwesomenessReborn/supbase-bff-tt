/*
Adds candidate_stage column to users table to track rushee progression through
the recruitment process. Stages include initial contact, interview rounds, bid
decisions, and acceptance outcomes.
*/

-- Add candidate_stage column to users table
ALTER TABLE users
ADD COLUMN candidate_stage TEXT CHECK (
  candidate_stage IN (
    'INITIAL',          -- First contact, registered interest
    'FIRST_ROUND',      -- Attending events, initial interviews
    'SECOND_ROUND',     -- Follow-up interviews, deeper engagement
    'THIRD_ROUND',      -- Final evaluation stage
    'BID_EXTENDED',     -- Bid has been offered
    'BID_ACCEPTED',     -- Candidate accepted the bid
    'BID_DECLINED',     -- Candidate declined the bid
    'NO_BID',           -- Decision made not to extend bid
    'DROPPED'           -- Candidate withdrew from rush
  )
);

-- Set default stage for existing RUSHEE users
UPDATE users
SET candidate_stage = 'INITIAL'
WHERE role = 'RUSHEE' AND candidate_stage IS NULL;

-- Create index for filtering by stage
CREATE INDEX idx_users_candidate_stage ON users(candidate_stage);

-- Add comment for documentation
COMMENT ON COLUMN users.candidate_stage IS 'Tracks progression of RUSHEE candidates through the recruitment process';

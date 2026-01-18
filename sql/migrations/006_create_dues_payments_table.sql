/*
Tracks financial dues and payments from members across semesters.
Records payment details, status (PAID/PARTIAL/NOT_PAID/OVERDUE/WAIVED), method,
and admin actions. Indexed for user lookups, status filtering, and semester reporting.
*/

-- Create dues_payments table
CREATE TABLE dues_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Payment Details
  amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
  payment_type TEXT NOT NULL CHECK (payment_type IN ('INITIATION', 'SEMESTER', 'SOCIAL', 'FINE', 'OTHER')),
  payment_method TEXT CHECK (payment_method IN ('CASH', 'VENMO', 'ZELLE', 'CHECK', 'BANK_TRANSFER', 'OTHER')),

  -- Status
  status TEXT NOT NULL DEFAULT 'NOT_PAID' CHECK (status IN ('PAID', 'PARTIAL', 'NOT_PAID', 'OVERDUE', 'WAIVED')),

  -- Dates
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,

  -- Financial Tracking
  semester TEXT,  -- "Fall 2024", "Spring 2025"
  reference_number TEXT,  -- Check number, Venmo transaction ID, etc.

  -- Notes
  notes TEXT,

  -- Admin Actions
  recorded_by UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_dues_user_id ON dues_payments(user_id);
CREATE INDEX idx_dues_status ON dues_payments(status);
CREATE INDEX idx_dues_due_date ON dues_payments(due_date);
CREATE INDEX idx_dues_semester ON dues_payments(semester);
CREATE INDEX idx_dues_payment_type ON dues_payments(payment_type);
CREATE INDEX idx_dues_recorded_by ON dues_payments(recorded_by);

-- Attach update timestamp trigger
CREATE TRIGGER update_dues_payments_updated_at
BEFORE UPDATE ON dues_payments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE dues_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own dues
CREATE POLICY "Users can view own dues"
ON dues_payments FOR SELECT
TO authenticated
USING (
  user_id IN (
    SELECT id FROM users WHERE supabase_id = auth.uid()
  )
);

-- RLS Policy: Admins can view all dues
CREATE POLICY "Admins can view all dues"
ON dues_payments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

-- RLS Policy: Only admins can create/update/delete dues records
CREATE POLICY "Admins can manage dues"
ON dues_payments FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.supabase_id = auth.uid()
    AND users.role = 'ADMIN'
    AND users.is_active = true
  )
);

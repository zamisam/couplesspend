-- Migration: Add expense split functionality
-- Description: Add columns to support different split types and debt tracking

-- Create split_type enum
CREATE TYPE IF NOT EXISTS split_type AS ENUM (
    'equal',        -- Default: split equally (both pay half)
    'full',         -- Spender pays full, partner owes half
    'partner_full', -- Partner pays full, spender owes half
    'no_split'      -- No split (personal expense)
);

-- Add new columns to expenses table
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS split_type split_type DEFAULT 'equal',
ADD COLUMN IF NOT EXISTS debt_amount NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS debtor_person person DEFAULT NULL;

-- Update existing expenses to have equal split
UPDATE expenses 
SET split_type = 'equal', 
    debt_amount = amount / 2,
    debtor_person = CASE 
        WHEN person = 'george' THEN 'james'
        WHEN person = 'james' THEN 'george'
        ELSE NULL
    END
WHERE split_type IS NULL;

-- Create index for efficient querying by split type
CREATE INDEX IF NOT EXISTS idx_expenses_split_type ON expenses(split_type);
CREATE INDEX IF NOT EXISTS idx_expenses_debtor_person ON expenses(debtor_person);

-- Comment the columns for clarity
COMMENT ON COLUMN expenses.split_type IS 'How the expense should be split between partners';
COMMENT ON COLUMN expenses.debt_amount IS 'Amount owed by the debtor (can be 0, half, or full amount)';
COMMENT ON COLUMN expenses.debtor_person IS 'Who owes money for this expense (null if no debt)';

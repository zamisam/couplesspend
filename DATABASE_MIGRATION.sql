-- Migration: Create partner_invitations table
-- Description: Table to manage partner invitations for expense sharing

-- Create partner_invitations table
CREATE TABLE IF NOT EXISTS partner_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    inviter_email TEXT NOT NULL,
    invitee_email TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(inviter_id, invitee_email)
);

-- Add partner_setup_complete column to auth.users
-- Note: This might need to be added to a custom users table instead
-- depending on your Supabase setup

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_partner_invitations_invitee_email ON partner_invitations(invitee_email);
CREATE INDEX IF NOT EXISTS idx_partner_invitations_inviter_id ON partner_invitations(inviter_id);

-- Enable RLS
ALTER TABLE partner_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see invitations they sent or received
CREATE POLICY "Users can view their own invitations" ON partner_invitations
    FOR SELECT USING (
        auth.uid() = inviter_id OR 
        auth.email() = invitee_email
    );

-- Users can only create invitations as themselves
CREATE POLICY "Users can create invitations" ON partner_invitations
    FOR INSERT WITH CHECK (auth.uid() = inviter_id);

-- Users can only update invitations they received (to accept/decline)
CREATE POLICY "Users can update received invitations" ON partner_invitations
    FOR UPDATE USING (auth.email() = invitee_email);

-- Create partnerships table to track active partnerships
CREATE TABLE IF NOT EXISTS partnerships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id != user2_id)
);

-- Enable RLS for partnerships
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;

-- RLS Policy for partnerships
CREATE POLICY "Users can view their partnerships" ON partnerships
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create partnerships" ON partnerships
    FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Create index for partnerships
CREATE INDEX IF NOT EXISTS idx_partnerships_user1 ON partnerships(user1_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_user2 ON partnerships(user2_id);

-- Add settled_date column to expenses table
-- This tracks when expenses were settled
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS settled_date TIMESTAMP WITH TIME ZONE;

-- Create index for efficient filtering by settlement status
CREATE INDEX IF NOT EXISTS idx_expenses_settled_date ON expenses(settled_date);
CREATE INDEX IF NOT EXISTS idx_expenses_settled_status ON expenses(settled, settled_date);

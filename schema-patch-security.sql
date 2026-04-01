-- =============================================================================
-- VESTED — Security Patch
-- Run this IF you already ran schema.sql on an existing Supabase project.
-- This patches the 5 security issues flagged by the Supabase linter:
--   - 2x security_definer_view  (ERROR)
--   - 3x function_search_path_mutable  (WARN)
-- It is safe to run multiple times (all statements are idempotent).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- FIX 1 of 5: set_updated_at — add fixed search_path
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- FIX 2 of 5: auth_email — add fixed search_path
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auth_email()
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT NULLIF(TRIM(current_setting('request.jwt.claims', true)::json->>'email'), '')
$$;

-- -----------------------------------------------------------------------------
-- FIX 3 of 5: is_admin — add fixed search_path
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE email = public.auth_email() AND role = 'admin'
  )
$$;

-- -----------------------------------------------------------------------------
-- FIX 4 of 5: admin_transactions view — drop and recreate with security_invoker
-- (CREATE OR REPLACE fails when column list has changed, e.g. after OTP patch)
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.admin_transactions;
CREATE VIEW public.admin_transactions
WITH (security_invoker = on) AS
SELECT
  t.*,
  u.full_name AS user_full_name,
  u.role      AS user_role
FROM public.transactions t
LEFT JOIN public.users u ON u.email = t.user_email;

-- -----------------------------------------------------------------------------
-- FIX 5 of 5: admin_user_summary view — drop and recreate with security_invoker
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.admin_user_summary;
CREATE VIEW public.admin_user_summary
WITH (security_invoker = on) AS
SELECT
  u.id, u.email, u.full_name, u.role, u.created_at,
  COALESCE(b.balance_usd, 0)       AS balance_usd,
  COALESCE(b.total_invested, 0)    AS total_invested,
  COALESCE(b.total_profit_loss, 0) AS total_profit_loss
FROM public.users u
LEFT JOIN public.user_balances b ON b.user_email = u.email;

-- -----------------------------------------------------------------------------
-- Also add missing INSERT policies (needed for first-login user row creation)
-- These use IF NOT EXISTS via DO block to avoid errors if already present
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_insert_own'
  ) THEN
    EXECUTE 'CREATE POLICY "users_insert_own" ON public.users FOR INSERT WITH CHECK (auth_id = auth.uid())';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'user_balances' AND policyname = 'balances_own_insert'
  ) THEN
    EXECUTE 'CREATE POLICY "balances_own_insert" ON public.user_balances FOR INSERT WITH CHECK (user_email = public.auth_email())';
  END IF;
END;
$$;

-- =============================================================================
-- Done. Re-run the Supabase database linter — all 5 issues should be gone.
-- =============================================================================

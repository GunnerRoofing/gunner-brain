-- provision_gunnerteam_app.sql  (B1 — GunnerTeam least-privilege DB role)
-- Run AS THE MASTER ROLE against the proxy-targeted masterdb cluster, ONE transaction.
-- Idempotent (safe to re-run). Touches only GunnerTeam's role + tables + a gunnerteam_app-
-- scoped policy on users — does NOT affect QP / WL-CompanyCam.
--
-- ⚠️ PASSWORD IS NOT IN THIS FILE. See the separate step at the bottom — never commit the password.
-- ⚠️ After this runs, MIRROR gunnerteam_app + the users policy into masterdb's SST config,
--    or a future masterdb deploy may drop them and re-break GunnerTeam auth.

BEGIN;

-- 1. Dedicated runtime role (no password here — set out-of-band, see bottom)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gunnerteam_app') THEN
    CREATE ROLE gunnerteam_app LOGIN NOSUPERUSER NOBYPASSRLS;
  ELSE
    ALTER ROLE gunnerteam_app NOSUPERUSER NOBYPASSRLS;  -- ensure attributes if it pre-exists
  END IF;
END $$;

-- 2. Schema + privilege grants
GRANT USAGE, CREATE ON SCHEMA public TO gunnerteam_app;        -- CREATE so GunnerTeam migrations can add gt_* tables
-- shared identity/auth tables GunnerTeam reads/writes (they carry org_id; the GUC below scopes RLS):
GRANT SELECT, INSERT, UPDATE, DELETE ON
  users, user_organizations, user_app_roles, crew_members,
  invite_tokens, reset_tokens, user_devices, audit_log
  TO gunnerteam_app;
GRANT SELECT ON organizations, apps, app_roles TO gunnerteam_app;
-- NOTE: this grant list = the masterdb tables GunnerTeam's code touches directly today.
-- The verify gate MUST include a real user-DELETE (exercises the full cascade incl. crew_members),
-- not just login + invite — a missing grant surfaces as a clear "permission denied" → add it.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO gunnerteam_app;

-- 3. Role-default GUC = the Gunner org id, resolved by slug (no hardcoded UUID).
--    Applied at backend-connection login → no client SET → no RDS-Proxy pinning;
--    survives RESET ALL/DISCARD ALL because it's the role default.
DO $$
DECLARE org_id uuid;
BEGIN
  SELECT id INTO org_id FROM organizations WHERE slug = 'gunner';
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'no organization with slug=gunner; aborting';
  END IF;
  EXECUTE format('ALTER ROLE gunnerteam_app SET app.current_org_id = %L', org_id);
END $$;

-- 4. users INSERT policy — lets complete-invite insert the user before its
--    user_organizations membership exists (SELECT/UPDATE/DELETE stay membership-scoped
--    via the existing org_isolation policy, so an unlinked user is still invisible).
DROP POLICY IF EXISTS gunnerteam_app_users_insert ON users;
CREATE POLICY gunnerteam_app_users_insert ON users
  FOR INSERT TO gunnerteam_app WITH CHECK (true);

-- 5. Reassign ownership of GunnerTeam's 27 gt_* tables (explicit list — NOT a wildcard,
--    so masterdb-owned tables like gt_id_map are deliberately excluded).
--    OWNER reassign requires the master role to be a member of the target role:
GRANT gunnerteam_app TO CURRENT_USER;
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'gt_achievements','gt_announcement_reads','gt_customer_photos','gt_job_bundle_cache',
    'gt_location_history','gt_org_theme','gt_phase_templates','gt_point_multipliers',
    'gt_point_rules','gt_points_balance','gt_points_exclusions','gt_points_ledger',
    'gt_receipt_line_items','gt_receipts','gt_redemptions','gt_rewards_catalog',
    'gt_service_keys','gt_task_cursors','gt_task_photos','gt_template_items',
    'gt_template_sections','gt_time_entries','gt_travel_pings','gt_user_achievement_progress',
    'gt_user_achievements','gt_user_location_status','gt_webhook_deliveries']
  LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=t) THEN
      EXECUTE format('ALTER TABLE public.%I OWNER TO gunnerteam_app', t);
    END IF;
  END LOOP;
END $$;
REVOKE gunnerteam_app FROM CURRENT_USER;

COMMIT;

-- Sanity check (run after): expect 27 owned by gunnerteam_app, gt_id_map still master-owned:
--   SELECT tableowner, count(*) FROM pg_tables WHERE tablename LIKE 'gt_%' GROUP BY 1;
--   SELECT current_setting('app.current_org_id');  -- via a gunnerteam_app connection → the gunner UUID

-- ── PASSWORD (separate, do NOT commit) ───────────────────────────────────────
-- Generate a strong password, then ONCE (not in any committed file/migration):
--   ALTER ROLE gunnerteam_app PASSWORD '<generated>';
-- and put the SAME value in: the proxy's Secrets Manager secret (so the proxy accepts it)
-- AND GunnerTeam's SSM /gunnerteam/dev/DB_PASSWORD (+ DB_USER=gunnerteam_app).
-- Then run cc-2137: swap creds → canary the new Lambda version via --qualifier
-- (non-empty login + a real complete-invite write + flat pinned-connections) → only then alias live.

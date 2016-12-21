-- Revert f_check_role_exists

BEGIN;

DROP FUNCTION IF EXISTS auth.check_role_exists() CASCADE;

COMMIT;

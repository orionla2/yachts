-- Revert f_clearance_for_role

BEGIN;

DROP FUNCTION IF EXISTS auth.clearance_for_role(name) CASCADE;
COMMIT;

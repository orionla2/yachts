-- Revert v_users

BEGIN;

DROP VIEW IF EXISTS users CASCADE;

COMMIT;

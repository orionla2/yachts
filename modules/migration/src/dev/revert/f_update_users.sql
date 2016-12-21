-- Revert f_update_users

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.update_users() CASCADE;
COMMIT;

-- Revert f_current_email

BEGIN;

DROP FUNCTION IF EXISTS auth.current_email() CASCADE;
COMMIT;

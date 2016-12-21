-- Revert f_send_validation

BEGIN;

DROP FUNCTION IF EXISTS auth.send_validation() CASCADE;
COMMIT;

-- Revert f_request_password_reset

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.request_password_reset(text) CASCADE;

COMMIT;

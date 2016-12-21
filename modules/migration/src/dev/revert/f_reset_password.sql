-- Revert f_reset_password

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.reset_password(text, uuid, text) CASCADE;

COMMIT;

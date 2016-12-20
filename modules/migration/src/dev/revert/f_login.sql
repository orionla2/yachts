-- Revert f_login

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.login(text, text) CASCADE;

COMMIT;

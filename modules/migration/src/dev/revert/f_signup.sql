-- Revert f_signup

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.signup(text, text, text, text, text) CASCADE;

COMMIT;

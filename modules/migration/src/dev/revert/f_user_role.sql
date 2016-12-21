-- Revert f_user_role

BEGIN;

DROP FUNCTION IF EXISTS auth.user_role(text, text) CASCADE;

COMMIT;

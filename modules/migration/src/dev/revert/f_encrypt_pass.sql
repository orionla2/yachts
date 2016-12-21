-- Revert f_encrypt_pass

BEGIN;

DROP FUNCTION IF EXISTS auth.encrypt_pass() CASCADE;
COMMIT;

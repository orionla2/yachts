-- Verify f_encrypt_pass

BEGIN;

SELECT has_function_privilege('auth.encrypt_pass()', 'execute');

ROLLBACK;

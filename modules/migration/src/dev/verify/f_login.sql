-- Verify f_login

BEGIN;

SELECT has_function_privilege('my_yacht.login(text, text)', 'execute');

ROLLBACK;

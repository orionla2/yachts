-- Verify f_signup

BEGIN;

SELECT has_function_privilege('my_yacht.signup(text, text, text, text, text)', 'execute');

ROLLBACK;

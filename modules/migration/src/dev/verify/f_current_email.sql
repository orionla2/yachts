-- Verify f_current_email

BEGIN;

SELECT has_function_privilege('auth.current_email()', 'execute');

ROLLBACK;

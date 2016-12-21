-- Verify f_send_validation

BEGIN;

SELECT has_function_privilege('auth.send_validation()', 'execute');

ROLLBACK;

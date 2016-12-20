-- Verify f_check_role_exists

BEGIN;

SELECT has_function_privilege('auth.check_role_exists()', 'execute');

ROLLBACK;

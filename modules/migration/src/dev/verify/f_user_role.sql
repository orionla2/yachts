-- Verify f_user_role

BEGIN;

SELECT has_function_privilege('auth.user_role(text, text)', 'execute');

ROLLBACK;

-- Verify f_clearance_for_role

BEGIN;

SELECT has_function_privilege('auth.clearance_for_role(name)', 'execute');

ROLLBACK;

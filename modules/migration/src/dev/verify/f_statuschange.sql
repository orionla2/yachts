-- Verify f_statuschange

BEGIN;

SELECT has_function_privilege('my_yacht.statuschange(integer, integer)', 'execute');

ROLLBACK;

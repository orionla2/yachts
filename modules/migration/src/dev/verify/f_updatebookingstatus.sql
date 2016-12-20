-- Verify f_updatebookingstatus

BEGIN;

SELECT has_function_privilege('my_yacht.updatebookingstatus(integer, integer)', 'execute');

ROLLBACK;

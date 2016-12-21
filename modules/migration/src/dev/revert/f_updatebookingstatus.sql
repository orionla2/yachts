-- Revert f_updatebookingstatus

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.updatebookingstatus(integer, integer) CASCADE;

COMMIT;

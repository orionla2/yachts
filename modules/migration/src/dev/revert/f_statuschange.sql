-- Revert f_statuschange

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.statuschange(integer, integer) CASCADE;

COMMIT;

-- Revert f_getid

BEGIN;

DROP FUNCTION IF EXISTS my_yacht.getid(text) CASCADE;

COMMIT;

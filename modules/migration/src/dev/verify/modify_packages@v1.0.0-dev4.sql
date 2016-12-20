-- Verify modify_packages

BEGIN;

-- XXX Add verifications here.
SELECT unit FROM my_yacht.packages WHERE FALSE;

ROLLBACK;

-- Deploy modify_packages
-- requires: appschema

BEGIN;

-- XXX Nothing to do.
ALTER TABLE my_yacht.packages drop COLUMN if exists unit cascade;

COMMIT;

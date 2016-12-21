-- Revert modify_packages

BEGIN;

-- XXX Add DDLs here.
ALTER TABLE my_yacht.packages drop COLUMN if exists unit cascade;

COMMIT;

-- Deploy modify_packages
-- requires: appschema

BEGIN;

-- XXX Add DDLs here.
ALTER TABLE my_yacht.packages ADD COLUMN unit character varying(40);
update my_yacht.packages set unit='';
ALTER TABLE my_yacht.packages ALTER COLUMN unit SET NOT NULL;

COMMIT;

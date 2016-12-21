-- Verify a_pg_authid

BEGIN;

select has_any_column_privilege('manager', 'pg_catalog.pg_authid', 'SELECT');
select has_any_column_privilege('user_role', 'pg_catalog.pg_authid', 'SELECT');
select has_any_column_privilege('guest', 'pg_catalog.pg_authid', 'SELECT');

ROLLBACK;
